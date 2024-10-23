//
//  NSFileVersion+Extension.swift
//
//  Created by cyan on 2024/10/16.
//

import AppKit

public extension NSFileVersion {
  var needsDownloading: Bool {
    !hasLocalContents && !FileManager.default.fileExists(atPath: url.path())
  }

  @MainActor
  func fetchLocalContents(
    startedDownloading: @Sendable @MainActor @escaping () -> Void,
    contentsFetched: @Sendable @MainActor @escaping () -> Void
  ) {
    guard needsDownloading else {
      return contentsFetched()
    }

    startedDownloading()
    DispatchQueue.global(qos: .userInitiated).async {
      let coordinator = NSFileCoordinator()
      coordinator.coordinate(readingItemAt: self.url, error: nil) { _ in
        DispatchQueue.main.async(execute: contentsFetched)
      }
    }
  }
}

public extension [NSFileVersion] {
  var newestToOldest: [Self.Element] {
    sorted { lhs, rhs in
      (lhs.modificationDate ?? .distantPast) > (rhs.modificationDate ?? .distantPast)
    }
  }
}

extension NSFileVersion: @unchecked @retroactive Sendable {}
