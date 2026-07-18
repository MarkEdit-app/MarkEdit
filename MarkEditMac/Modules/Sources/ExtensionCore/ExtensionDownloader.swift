//
//  ExtensionDownloader.swift
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
public enum ExtensionDownloader {
  public enum Failure: Error {
    case invalidURL
    case invalidIdentifier
    case downloadFailed
    case integrityMismatch
    case incompatible(minAppVersion: String)
    case writeFailed
  }

  /// Downloads `entry.latest`, verifies its hash, and installs it, returning the record to persist.
  public static func install(entry: ExtensionEntry) async throws -> ExtensionConfig.Installed {
    try await install(id: entry.id, release: entry.latest)
  }

  public static func install(id: String, release: ExtensionRelease) async throws -> ExtensionConfig.Installed {
    guard release.isCompatible else {
      throw Failure.incompatible(minAppVersion: release.minAppVersion ?? "")
    }

    guard isSafeIdentifier(id) else {
      throw Failure.invalidIdentifier
    }

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
      installDate: Date.now.ISO8601Format()
    )
  }

  /// Installs from a raw url the user provided, for extensions not in the registry.
  ///
  /// The id is derived from the filename and the hash is pinned from what was downloaded.
  public static func install(url: URL) async throws -> ExtensionConfig.Installed {
    let data = try await download(from: url)
    let id = ExtensionConfig.identifier(fromFileName: url.lastPathComponent)
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
      installDate: Date.now.ISO8601Format()
    )
  }

  /// Download the latest release and merge preserved user fields.
  public static func downloadUpdate(
    for installed: ExtensionConfig.Installed,
    entry: ExtensionEntry
  ) async throws -> ExtensionConfig.Installed {
    let record = try await install(id: entry.id, release: entry.latest)
    return record.merging(preserving: installed)
  }

  /// Delete the script file and remove its installed record.
  public static func uninstall(_ installed: ExtensionConfig.Installed) {
    let fileName = installed.file
    if !fileName.isEmpty, fileName == (fileName as NSString).lastPathComponent {
      let fileURL = ExtensionEnvironment.scriptsDirectory.appending(path: fileName, directoryHint: .notDirectory)
      try? FileManager.default.removeItem(at: fileURL)
    }

    ExtensionConfig.remove(id: installed.id)
  }
}

// MARK: - Private

private extension ExtensionDownloader {
  /// Whether `id` is safe to use as a file name component, guarding against path traversal.
  static func isSafeIdentifier(_ id: String) -> Bool {
    guard !id.isEmpty, !id.hasPrefix("."), !id.contains("..") else {
      return false
    }

    return id.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" || $0 == ".") }
  }

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

  /// Writes the file atomically, replacing any existing copy.
  static func write(data: Data, fileName: String) -> Bool {
    let directory = ExtensionEnvironment.scriptsDirectory
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
