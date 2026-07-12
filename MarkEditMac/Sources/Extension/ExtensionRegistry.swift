//
//  ExtensionRegistry.swift
//  MarkEditMac
//
//  Created by cyan on 7/11/26.
//

import Foundation
import AppKitExtensions
import MarkEditKit

/// Newest compatible release for an entry.
struct ExtensionRelease: Codable, Equatable, Sendable {
  let version: String
  let url: String
  let sha256: String
  let minAppVersion: String?
  let notes: String?
}

extension ExtensionRelease {
  /// Whether the running app meets this release's minimum version requirement.
  var isCompatible: Bool {
    guard let minAppVersion, !minAppVersion.isEmpty else {
      return true
    }

    let current = Bundle.main.shortVersionString ?? "0.0.0"
    return minAppVersion.compare(current, options: .numeric) != .orderedDescending
  }
}

/// A single extension or theme in the registry index.
struct ExtensionEntry: Codable, Equatable, Sendable {
  enum Category: String, Codable, Sendable {
    case `extension`
    case theme
  }

  enum ColorScheme: String, Codable, Sendable {
    case light
    case dark
    case both
  }

  let id: String
  let name: String
  let description: String
  let author: String
  let homepage: String
  let category: Category
  let colorScheme: ColorScheme?
  let screenshots: [String]?
  let latest: ExtensionRelease
}

/// The registry index the app reads, built by CI from the extensions repo.
struct ExtensionIndex: Codable, Equatable, Sendable {
  let schemaVersion: Int
  let extensions: [ExtensionEntry]
}

/// Fetches and caches the registry index.
///
/// A conditional GET revalidates the cache (304, no body), the last good index is kept
/// on disk and returned when offline or when a check is skipped.
enum ExtensionRegistry {
  /// Most recently cached index, if any.
  static var cachedIndex: ExtensionIndex? {
    guard let data = try? Data(contentsOf: Cache.indexURL) else {
      return nil
    }

    return try? JSONDecoder().decode(ExtensionIndex.self, from: data)
  }

  /// Whether a cadence-driven check is currently due.
  static var isCheckDue: Bool {
    shouldCheck
  }

  /// Refreshes the index from the network, honoring the configured cadence.
  ///
  /// - Parameter force: bypass the cadence check, e.g. a manual "Refresh".
  @discardableResult
  static func refresh(force: Bool = false) async -> ExtensionIndex? {
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

      Cache.save(indexData: data, etag: httpResponse.value(forHTTPHeaderField: "ETag"))
      return index
    default:
      Logger.log(.error, "Unexpected registry status code: \(httpResponse.statusCode)")
      Cache.touch()
      return cachedIndex
    }
  }
}

// MARK: - Private

private extension ExtensionRegistry {
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
      URL.cachesDirectory.appending(path: "Extensions", directoryHint: .isDirectory)
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
