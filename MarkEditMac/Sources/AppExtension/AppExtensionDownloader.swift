//
//  AppExtensionDownloader.swift
//  MarkEditMac
//
//  Created by cyan on 7/11/26.
//

import Foundation
import MarkEditCore
import MarkEditKit

/// Downloads an extension's JavaScript and installs it under scripts/<id>.js.
///
/// The file name derives from the registry id, not the source url, and the download is
/// verified against the pinned sha256 before it replaces any existing file.
enum AppExtensionDownloader {
  enum Failure: Error {
    case invalidURL
    case downloadFailed
    case integrityMismatch
    case writeFailed
  }

  /// Downloads `entry.latest`, verifies its hash, and installs it, returning the record to persist.
  static func install(entry: AppExtensionEntry) async throws -> AppExtensionConfig.Installed {
    try await install(id: entry.id, release: entry.latest)
  }

  static func install(id: String, release: AppExtensionRelease) async throws -> AppExtensionConfig.Installed {
    guard let url = URL(string: release.url) else {
      throw Failure.invalidURL
    }

    guard let (data, response) = try? await URLSession.shared.data(from: url) else {
      throw Failure.downloadFailed
    }

    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
      throw Failure.downloadFailed
    }

    guard data.sha256Hash == release.sha256.lowercased() else {
      throw Failure.integrityMismatch
    }

    // Prefer [id].js to the filename from the downloaded file
    let fileName = "\(id).js"
    guard write(data: data, fileName: fileName) else {
      throw Failure.writeFailed
    }

    return AppExtensionConfig.Installed(
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
}

// MARK: - Private

private extension AppExtensionDownloader {
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
