//
//  ExtensionDownloader.swift
//  MarkEditMac
//
//  Created by cyan on 7/11/26.
//

import Foundation
import MarkEditCore
import MarkEditKit

/// Downloads an extension's JavaScript and installs it under scripts/<id>.js.
///
/// The file name derives from the id, not the source url. The registry lane verifies the
/// pinned sha256; the URL lane pins the hash of whatever was downloaded.
enum ExtensionDownloader {
  enum Failure: Error {
    case invalidURL
    case downloadFailed
    case integrityMismatch
    case writeFailed
  }

  /// Downloads `entry.latest`, verifies its hash, and installs it, returning the record to persist.
  static func install(entry: ExtensionEntry) async throws -> ExtensionConfig.Installed {
    try await install(id: entry.id, release: entry.latest)
  }

  static func install(id: String, release: ExtensionRelease) async throws -> ExtensionConfig.Installed {
    guard let url = URL(string: release.url) else {
      throw Failure.invalidURL
    }

    let data = try await download(from: url)
    guard data.sha256Hash == release.sha256.lowercased() else {
      throw Failure.integrityMismatch
    }

    // Prefer [id].js to the filename from the downloaded file
    let fileName = "\(id).js"
    guard write(data: data, fileName: fileName) else {
      throw Failure.writeFailed
    }

    return ExtensionConfig.Installed(
      id: id,
      version: release.version,
      url: release.url,
      sha256: release.sha256,
      file: fileName,
      enabled: true,
      updateCheck: nil,
      installDate: ISO8601DateFormatter().string(from: .now)
    )
  }

  /// Installs from a raw url the user provided, for extensions not in the registry.
  ///
  /// The id is derived from the filename, the hash is pinned from what was downloaded,
  /// and updates default to `never` (re-install to update).
  static func install(url: URL) async throws -> ExtensionConfig.Installed {
    let data = try await download(from: url)
    let id = identifier(from: url)
    let fileName = "\(id).js"
    guard write(data: data, fileName: fileName) else {
      throw Failure.writeFailed
    }

    return ExtensionConfig.Installed(
      id: id,
      version: nil,
      url: url.absoluteString,
      sha256: data.sha256Hash,
      file: fileName,
      enabled: true,
      updateCheck: .never,
      installDate: ISO8601DateFormatter().string(from: .now)
    )
  }
}

// MARK: - Private

private extension ExtensionDownloader {
  /// Downloads over HTTPS, returning the body on a 200 response.
  static func download(from url: URL) async throws -> Data {
    guard url.scheme?.lowercased() == "https" else {
      throw Failure.invalidURL
    }

    guard let (data, response) = try? await URLSession.shared.data(from: url) else {
      throw Failure.downloadFailed
    }

    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
      throw Failure.downloadFailed
    }

    return data
  }

  /// Derives a kebab-case id from the url filename, e.g. ".../markedit-preview.js" -> "markedit-preview".
  static func identifier(from url: URL) -> String {
    ExtensionConfig.identifier(fromFileName: url.lastPathComponent)
  }

  /// Writes the file atomically, replacing any existing copy.
  static func write(data: Data, fileName: String) -> Bool {
    let directory = AppCustomization.scriptsDirectory.fileURL
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    do {
      try data.write(to: directory.appending(path: fileName, directoryHint: .notDirectory), options: .atomic)
      return true
    } catch {
      Logger.log(.error, "Failed to write extension file: \(fileName)")
      return false
    }
  }
}
