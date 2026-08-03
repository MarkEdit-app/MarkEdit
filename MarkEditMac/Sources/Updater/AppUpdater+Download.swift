//
//  AppUpdater+Download.swift
//  MarkEditMac
//
//  Created by cyan on 8/2/26.
//

import AppKit
import MarkEditKit

@MainActor
extension AppUpdater {
  /// Downloads a release asset to a temporary file.
  static func download(_ asset: AppVersion.Asset) async throws -> URL {
    guard let url = URL(string: asset.browserDownloadUrl) else {
      throw Failure.missingAsset
    }

    let (location, response) = try await URLSession.shared.download(from: url)
    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
      try? FileManager.default.removeItem(at: location)
      throw Failure.downloadFailed
    }

    // Never use the remote filename on disk
    let destination = FileManager.default.temporaryDirectory.appending(path: "UpdateArchive.zip")
    try? FileManager.default.removeItem(at: destination)

    try FileManager.default.moveItem(at: location, to: destination)
    return destination
  }
}
