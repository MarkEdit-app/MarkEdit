//
//  TextBundleAssets.swift
//
//  Created by cyan on 4/27/26.
//

import Foundation

public enum TextBundleAssets {
  /// Copy a file into the textbundle's `assets/` folder under a non-colliding name,
  /// and return the bundle-relative path (e.g. `assets/photo.png`).
  public static func copy(from source: URL, into bundleURL: URL) throws -> String {
    let assetsFolder = FileNames.assetsFolder
    let assetsURL = bundleURL.appending(path: assetsFolder, directoryHint: .isDirectory)

    let fileManager = FileManager.default
    try fileManager.createDirectory(at: assetsURL, withIntermediateDirectories: true)

    let existing = (try? fileManager.contentsOfDirectory(atPath: assetsURL.path(percentEncoded: false))) ?? []
    let fileName = uniqueFileName(for: source, existing: Set(existing))
    let destination = assetsURL.appending(path: fileName)

    try fileManager.copyItem(at: source, to: destination)
    return "\(assetsFolder)/\(fileName)"
  }
}

// MARK: - Private

private extension TextBundleAssets {
  /// Returns `source.lastPathComponent`, or `name-1.ext`, `name-2.ext`, ... on collision.
  static func uniqueFileName(for source: URL, existing: Set<String>) -> String {
    let preferred = source.lastPathComponent
    guard existing.contains(preferred) else {
      return preferred
    }

    // Insert the suffix before the dot, e.g. "photo.png" -> "photo-1.png".
    let pathExtension = source.pathExtension
    let baseName = source.deletingPathExtension().lastPathComponent
    let suffix = pathExtension.isEmpty ? "" : ".\(pathExtension)"

    var index = 1
    while true {
      let candidate = "\(baseName)-\(index)\(suffix)"
      if !existing.contains(candidate) {
        return candidate
      }

      index += 1
    }
  }
}
