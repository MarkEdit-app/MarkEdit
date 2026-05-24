//
//  URL+Extension.swift
//
//  Created by cyan on 12/23/25.
//

import Foundation

public extension URL {
  static var standardDirectories: [String: String] {
    [
      "home": Self.homeDirectory,
      "documents": Self.documentsDirectory,
      "library": Self.libraryDirectory,
      "caches": Self.cachesDirectory,
      "temporary": Self.temporaryDirectory,
      "sharedContainer": Self.sharedContainerURL,
    ].compactMapValues {
      $0?.path(percentEncoded: false)
    }
  }

  static var sharedContainerURL: URL? {
    FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.app.cyan.markedit")
  }

  /// Files in this directory whose extension is in `types`, sorted by localized filename order.
  func sortedFiles(types: Set<String>) -> [URL] {
    let files = (try? FileManager.default.contentsOfDirectory(
      at: self,
      includingPropertiesForKeys: nil
    )) ?? []

    return files
      .filter { types.contains($0.pathExtension.lowercased()) }
      .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
  }
}
