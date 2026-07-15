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
  public let colorPatterns: [String]?
  public let latest: ExtensionRelease

  public init(
    id: String,
    name: String,
    description: String,
    author: String,
    homepage: String,
    category: Category,
    colorScheme: ColorScheme?,
    colorPatterns: [String]?,
    latest: ExtensionRelease
  ) {
    self.id = id
    self.name = name
    self.description = description
    self.author = author
    self.homepage = homepage
    self.category = category
    self.colorScheme = colorScheme
    self.colorPatterns = colorPatterns
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

  /// Whether the user-facing update prompt is due.
  public static var shouldPromptUpdates: Bool {
  #if DEBUG
    // A mock index makes every check fire, so the update flow is easy to trigger
    if mockIndex != nil {
      return true
    }
  #endif

    switch ExtensionConfig.updateCheck {
    case .never: return false
    case .onLaunch: return true
    case .daily: return elapsedSincePrompt >= Constants.day
    case .weekly: return elapsedSincePrompt >= Constants.week
    }
  }

  /// Record that update prompt cadence has been satisfied.
  public static func recordUpdatePrompt() {
    Cache.recordPrompt()
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

    // Fetch when forced, when the index is due for revalidation, or when there's no usable cache
    // to fall back on (index.json deleted or fails to decode while metadata.json still looks recent).
    let cached = cachedIndex
    guard force || shouldRefreshIndex || cached == nil else {
      return cached
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

    // Only revalidate when there's a cached body a 304 can fall back on, otherwise force a full fetch
    if cached != nil, let etag = Cache.metadata?.etag {
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
      return fallbackIndex()
    case 200:
      guard let index = try? JSONDecoder().decode(ExtensionIndex.self, from: data) else {
        Logger.log(.error, "Failed to decode the registry index")
        return fallbackIndex()
      }

      guard index.isSupported else {
        Logger.log(.error, "Registry schemaVersion \(index.schemaVersion) is newer than supported, update MarkEdit")
        return fallbackIndex()
      }

      Cache.save(indexData: data, etag: httpResponse.value(forHTTPHeaderField: "ETag"))
      return index
    default:
      Logger.log(.error, "Unexpected registry status code: \(httpResponse.statusCode)")
      return fallbackIndex()
    }
  }

  /// Version-tracked installs with a newer, compatible release in the registry.
  public static func availableUpdates(
    index: ExtensionIndex,
    installed: [ExtensionConfig.Installed] = ExtensionConfig.installed
  ) -> [ExtensionUpdate] {
    installed.compactMap { installed in
      // Only version-tracked installs can be compared for updates
      guard let version = installed.version else {
        return nil
      }

      guard let entry = index.extensions.first(where: { $0.id == installed.id }) else {
        return nil
      }

      // Skip releases the current app can't run
      guard entry.latest.isCompatible else {
        return nil
      }

      // Honor a per-extension "never" freeze
      guard installed.updateCheck != .never else {
        return nil
      }

      // Skip older or equal versions
      guard entry.latest.version.compare(version, options: .numeric) == .orderedDescending else {
        return nil
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

  /// The cached index to use when a refresh can't produce a new one.
  ///
  /// Records the check (backing off the cadence) only when a cache actually exists.
  /// With no cache, `lastChecked` is left untouched so the next launch or timer retries
  /// soon instead of waiting out the full cadence with no usable index.
  static func fallbackIndex() -> ExtensionIndex? {
    let cached = cachedIndex
    if cached != nil {
      Cache.touch()
    }

    return cached
  }

  /// Background index revalidation cadence.
  static var shouldRefreshIndex: Bool {
    guard ExtensionConfig.updateCheck != .never else {
      return false
    }

    return elapsedSinceLastCheck >= Constants.indexTTL
  }

  static var elapsedSinceLastCheck: TimeInterval {
    guard let lastChecked = Cache.metadata?.lastChecked else {
      return .greatestFiniteMagnitude
    }

    return Date.now.timeIntervalSince(lastChecked)
  }

  static var elapsedSincePrompt: TimeInterval {
    guard let lastPrompted = Cache.metadata?.lastPrompted else {
      return .greatestFiniteMagnitude
    }

    return Date.now.timeIntervalSince(lastPrompted)
  }

  enum Constants {
    static let hour: TimeInterval = 60 * 60
    static let day: TimeInterval = 24 * hour
    static let week: TimeInterval = 7 * day

    /// Keep the catalog current without waiting out the prompt cadence.
    static let indexTTL: TimeInterval = hour
  }

  /// On-disk cache of the index bytes plus revalidation metadata.
  enum Cache {
    struct Metadata: Codable {
      let etag: String?
      let lastChecked: Date
      let lastPrompted: Date?
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
      write(metadata: Metadata(etag: etag, lastChecked: .now, lastPrompted: metadata?.lastPrompted))
    }

    /// Record a check that returned no body (304), preserving the etag.
    static func touch() {
      write(metadata: Metadata(etag: metadata?.etag, lastChecked: .now, lastPrompted: metadata?.lastPrompted))
    }

    /// Record that the update prompt was just shown.
    static func recordPrompt() {
      let current = metadata
      write(metadata: Metadata(etag: current?.etag, lastChecked: current?.lastChecked ?? .now, lastPrompted: .now))
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
