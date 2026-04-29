//
//  FileDropHandler.swift
//
//  Created by cyan on 4/27/26.
//

import Foundation
import MarkEditKit
import TextBundle

public enum FileDropHandler {
  /// Build the Markdown snippet to insert for files dropped onto the editor.
  ///
  /// For `.textbundle` documents, dropped files are copied into the bundle's `assets/`
  /// folder as a side effect; otherwise files on disk are not touched.
  ///
  /// Returns `![]()`/`[]()` links joined by `lineBreak`, or `nil` if nothing to insert.
  public static func handle(
    fileURLs: [URL],
    documentURL: URL?,
    documentType: String?,
    lineBreak: String
  ) -> String? {
    let isTextBundle = documentType?.isTextBundle == true
    let lines = fileURLs.compactMap {
      handle(fileURL: $0, documentURL: documentURL, isTextBundle: isTextBundle)
    }

    return lines.isEmpty ? nil : lines.joined(separator: lineBreak)
  }
}

// MARK: - Private

private extension FileDropHandler {
  static func handle(fileURL: URL, documentURL: URL?, isTextBundle: Bool) -> String? {
    // textbundle: copy into assets/. Saved doc: relative path. Untitled: absolute path.
    let target: String? = {
      if isTextBundle, let bundleURL = documentURL {
        do {
          return try TextBundleAssets.copy(from: fileURL, into: bundleURL)
        } catch {
          Logger.log(.error, "Failed to copy dropped file into textbundle: \(error)")
          return nil
        }
      } else if let parentURL = documentURL?.deletingLastPathComponent() {
        return fileURL.relativePath(from: parentURL)
      } else {
        return fileURL.path(percentEncoded: false)
      }
    }()

    guard let target else {
      return nil
    }

    return MarkdownLink.formatted(
      label: fileURL.lastPathComponent,
      target: target,
      isImage: fileURL.isImageFile
    )
  }
}
