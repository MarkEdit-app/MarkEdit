//
//  ExtensionRegistry.swift
//
//  Created by cyan on 7/11/26.
//

import Foundation
import MarkEditCore
import MarkEditKit

/// Newest compatible release for an entry.
public struct ExtensionRelease: Codable, Equatable, Sendable {
  public let version: String
  public let url: String
  public let sha256: String
  public let minAppVersion: String?
  public let notes: String?

  public init(
    version: String,
    url: String,
    sha256: String,
    minAppVersion: String?,
    notes: String?
  ) {
    self.version = version
    self.url = url
    self.sha256 = sha256
    self.minAppVersion = minAppVersion
    self.notes = notes
  }
}

public extension ExtensionRelease {
  /// Whether the running app meets this release's minimum version requirement.
  var isCompatible: Bool {
    guard let minAppVersion, !minAppVersion.isEmpty else {
      return true
    }

    let current = ExtensionEnvironment.appVersion
    return minAppVersion.compare(current, options: .numeric) != .orderedDescending
  }
}

/// A single extension or theme in the registry index.
public struct ExtensionEntry: Codable, Equatable, Sendable {
  public enum Category: String, Codable, Sendable {
    case `extension`
    case theme
  }

  public enum ColorScheme: String, Codable, Sendable {
    case light
    case dark
    case both
  }

  public let id: String
  public let name: String
  public let description: String
  public let author: String
  public let homepage: String
  public let category: Category
  public let colorScheme: ColorScheme?
  public let screenshots: [String]?
  public let latest: ExtensionRelease

  public init(
    id: String,
    name: String,
    description: String,
    author: String,
    homepage: String,
    category: Category,
    colorScheme: ColorScheme?,
    screenshots: [String]?,
    latest: ExtensionRelease
  ) {
    self.id = id
    self.name = name
    self.description = description
    self.author = author
    self.homepage = homepage
    self.category = category
    self.colorScheme = colorScheme
    self.screenshots = screenshots
    self.latest = latest
  }
}

/// The registry index the app reads, built by CI from the extensions repo.
public struct ExtensionIndex: Codable, Equatable, Sendable {
  /// Highest schema version this app understands; bump when the index format changes incompatibly.
  public static let supportedSchemaVersion = 1

  public let schemaVersion: Int
  public let extensions: [ExtensionEntry]

  public init(schemaVersion: Int, extensions: [ExtensionEntry]) {
    self.schemaVersion = schemaVersion
    self.extensions = extensions
  }

  /// Whether the app can read this index; a newer schema means the app is out of date.
  public var isSupported: Bool {
    schemaVersion <= Self.supportedSchemaVersion
  }
}

/// An installed extension paired with its newer registry entry.
public struct ExtensionUpdate: Sendable {
  public let installed: ExtensionConfig.Installed
  public let entry: ExtensionEntry
}

/// Fetches and caches the registry index.
///
/// A conditional GET revalidates the cache (304, no body), the last good index is kept
/// on disk and returned when offline or when a check is skipped.
public enum ExtensionRegistry {
  /// Most recently cached index, if any.
  public static var cachedIndex: ExtensionIndex? {
    guard let data = try? Data(contentsOf: Cache.indexURL) else {
      return nil
    }

    guard let index = try? JSONDecoder().decode(ExtensionIndex.self, from: data) else {
      return nil
    }

    return index.isSupported ? index : nil
  }

  /// Whether a cadence-driven check is currently due.
  public static var isCheckDue: Bool {
  #if DEBUG
    // A mock index makes every check fire, so the update flow is easy to trigger
    if mockIndex != nil {
      return true
    }
  #endif

    return shouldCheck
  }

  /// Refreshes the index from the network, honoring the configured cadence.
  ///
  /// - Parameter force: bypass the cadence check, e.g. a manual "Refresh".
  @discardableResult
  public static func refresh(force: Bool = false) async -> ExtensionIndex? {
  #if DEBUG
    // Bypass the network and serve a hand-authored index when present
    if let mockIndex {
      return mockIndex
    }
  #endif

    guard force || shouldCheck else {
      return cachedIndex
    }

    guard let url = ExtensionConfig.registryURL else {
      Logger.log(.error, "Invalid registry url in extensions.json")
      return cachedIndex
    }

    guard url.scheme?.lowercased() == "https" else {
      Logger.log(.error, "Registry url must be served over https")
      return cachedIndex
    }

    var request = URLRequest(url: url)
    request.cachePolicy = .reloadIgnoringLocalCacheData // We manage revalidation ourselves
    if let etag = Cache.metadata?.etag {
      request.setValue(etag, forHTTPHeaderField: "If-None-Match")
    }

    guard let (data, response) = try? await URLSession.shared.data(for: request) else {
      Logger.log(.error, "Failed to reach the extension registry")
      return cachedIndex
    }

    guard let httpResponse = response as? HTTPURLResponse else {
      Logger.log(.error, "Invalid response from the extension registry")
      return cachedIndex
    }

    switch httpResponse.statusCode {
    case 304:
      // Not Modified, the cache is still current
      Cache.touch()
      return cachedIndex
    case 200:
      guard let index = try? JSONDecoder().decode(ExtensionIndex.self, from: data) else {
        Logger.log(.error, "Failed to decode the registry index")
        Cache.touch()
        return cachedIndex
      }

      guard index.isSupported else {
        Logger.log(.error, "Registry schemaVersion \(index.schemaVersion) is newer than supported, update MarkEdit")
        Cache.touch()
        return cachedIndex
      }

      Cache.save(indexData: data, etag: httpResponse.value(forHTTPHeaderField: "ETag"))
      return index
    default:
      Logger.log(.error, "Unexpected registry status code: \(httpResponse.statusCode)")
      Cache.touch()
      return cachedIndex
    }
  }

  /// Installed extensions with a newer, compatible release in the registry.
  ///
  /// Version-less installs (adopted from disk or installed by url) can't be compared, but
  /// official "markedit-" ids almost certainly come from the registry, so their latest release
  /// is offered to adopt them into version tracking.
  public static func availableUpdates(
    index: ExtensionIndex,
    installed: [ExtensionConfig.Installed] = ExtensionConfig.installed
  ) -> [ExtensionUpdate] {
    installed.compactMap { installed in
      guard let entry = index.extensions.first(where: { $0.id == installed.id }) else {
        return nil
      }

      // Skip releases the current app can't run
      guard entry.latest.isCompatible else {
        return nil
      }

      if let version = installed.version {
        // Honor a per-extension "never" freeze for tracked installs
        guard installed.updateCheck != .never else {
          return nil
        }

        // Skip older or equal versions
        guard entry.latest.version.compare(version, options: .numeric) == .orderedDescending else {
          return nil
        }
      } else {
        // Untracked: only adopt ids that are almost certainly official
        guard installed.id.hasPrefixIgnoreCase("markedit-") else {
          return nil
        }
      }

      return ExtensionUpdate(installed: installed, entry: entry)
    }
  }
}

// MARK: - Private

private extension ExtensionRegistry {
#if DEBUG
  /// Reads debug/mock-index.json, if the user placed one there for testing.
  static var mockIndex: ExtensionIndex? {
    let url = ExtensionEnvironment.debugDirectory.appending(path: "mock-index.json", directoryHint: .notDirectory)
    guard let data = try? Data(contentsOf: url) else {
      return nil
    }

    return try? JSONDecoder().decode(ExtensionIndex.self, from: data)
  }
#endif

  static var shouldCheck: Bool {
    switch ExtensionConfig.updateCheck {
    case .never: return false
    case .onLaunch: return true
    case .daily: return elapsedSinceLastCheck >= Constants.day
    case .weekly: return elapsedSinceLastCheck >= Constants.week
    }
  }

  static var elapsedSinceLastCheck: TimeInterval {
    guard let lastChecked = Cache.metadata?.lastChecked else {
      return .greatestFiniteMagnitude
    }

    return Date.now.timeIntervalSince(lastChecked)
  }

  enum Constants {
    static let day: TimeInterval = 24 * 60 * 60
    static let week: TimeInterval = 7 * day
  }

  /// On-disk cache of the index bytes plus revalidation metadata.
  enum Cache {
    struct Metadata: Codable {
      let etag: String?
      let lastChecked: Date
    }

    static var indexURL: URL {
      directory.appending(path: "index.json", directoryHint: .notDirectory)
    }

    static var metadata: Metadata? {
      guard let data = try? Data(contentsOf: metadataURL) else {
        return nil
      }

      return try? JSONDecoder().decode(Metadata.self, from: data)
    }

    static func save(indexData: Data, etag: String?) {
      ensureDirectory()

      try? indexData.write(to: indexURL, options: .atomic)
      write(metadata: Metadata(etag: etag, lastChecked: .now))
    }

    /// Record a check that returned no body (304), preserving the etag.
    static func touch() {
      write(metadata: Metadata(etag: metadata?.etag, lastChecked: .now))
    }

    private static var directory: URL {
      ExtensionEnvironment.indexCacheDirectory
    }

    private static var metadataURL: URL {
      directory.appending(path: "metadata.json", directoryHint: .notDirectory)
    }

    private static func write(metadata: Metadata) {
      ensureDirectory()

      if let data = try? JSONEncoder().encode(metadata) {
        try? data.write(to: metadataURL, options: .atomic)
      }
    }

    private static func ensureDirectory() {
      try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }
  }
}
