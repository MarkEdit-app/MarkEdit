//
//  NSFileVersion+Extension.swift
//
//  Created by cyan on 10/16/24.
//

import AppKit

public extension NSFileVersion {
  var needsDownloading: Bool {
    !hasLocalContents && !FileManager.default.fileExists(atPath: url.path)
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
  func newestToOldest(throttle: Bool = true) -> [Self.Element] {
    let comparator: (Self.Element, Self.Element) -> Bool = { lhs, rhs in
      (lhs.modificationDate ?? .distantPast) > (rhs.modificationDate ?? .distantPast)
    }

    guard throttle else {
      return sorted(by: comparator)
    }

    var seen = Set<Int>()
    return filter {
      // If multiple versions are created within one second, only keep the first one
      let id = Int(($0.modificationDate ?? .distantPast).timeIntervalSinceReferenceDate)
      return seen.insert(id).inserted
    }
    .sorted(by: comparator)
  }
}

extension NSFileVersion: @unchecked @retroactive Sendable {}
