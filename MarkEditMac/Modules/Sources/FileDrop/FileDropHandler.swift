//
//  FileDropHandler.swift
//
//  Created by cyan on 4/27/26.
//

import Foundation
import MarkEditKit
import TextBundle

public enum FileDropHandler {
  /// Build the Markdown snippet to insert for a single file dropped onto the editor.
  ///
  /// For `.textbundle` documents, the dropped file is copied into the bundle's `assets/`
  /// folder as a side effect; otherwise the file on disk is not touched.
  ///
  /// Returns a `![]()` or `[]()` link.
  public static func handle(
    fileURL: URL,
    documentURL: URL?,
    documentType: String?
  ) -> String {
    let isTextBundle = documentType?.isTextBundle == true
    return handle(fileURL: fileURL, documentURL: documentURL, isTextBundle: isTextBundle)
  }
}

// MARK: - Private

private extension FileDropHandler {
  static func handle(fileURL: URL, documentURL: URL?, isTextBundle: Bool) -> String {
    // textbundle: copy into assets/. Saved doc: relative path. Untitled: absolute path.
    let target: String = {
      if isTextBundle, let bundleURL = documentURL {
        do {
          return try TextBundleAssets.copy(from: fileURL, into: bundleURL)
        } catch {
          Logger.log(.error, "Failed to copy dropped file into textbundle: \(error)")
          return fileURL.relativePath(from: bundleURL)
        }
      } else if let parentURL = documentURL?.deletingLastPathComponent() {
        return fileURL.relativePath(from: parentURL)
      } else {
        return fileURL.path(percentEncoded: false)
      }
    }()

    return MarkdownLink.formatted(
      label: fileURL.lastPathComponent,
      target: target,
      isImage: fileURL.isImageFile
    )
  }
}
