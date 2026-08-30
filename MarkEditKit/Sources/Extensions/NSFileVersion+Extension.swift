//
//  NSFileVersion+Extension.swift
//
//  Created by cyan on 8/24/26.
//

import Foundation

public extension NSFileVersion {
  var needsDownloading: Bool {
    !hasLocalContents && !FileManager.default.fileExists(atPath: url.path)
  }

  func fetchLocalContents() async -> Bool {
    guard needsDownloading else {
      return true
    }

    let url = url
    return await withCheckedContinuation { continuation in
      DispatchQueue.global(qos: .userInitiated).async {
        var error: NSError?
        var succeeded = false

        let coordinator = NSFileCoordinator()
        coordinator.coordinate(readingItemAt: url, error: &error) { _ in
          succeeded = true
        }

        continuation.resume(returning: error == nil && succeeded)
      }
    }
  }

  func removeFromDisk(for itemURL: URL) async throws {
    try await withCheckedThrowingContinuation { continuation in
      DispatchQueue.global(qos: .utility).async {
        var error: NSError?
        var result: Result<Void, Error> = .failure(CocoaError(.fileWriteUnknown))

        NSFileCoordinator().coordinate(writingItemAt: itemURL, error: &error) { _ in
          result = Result { try self.remove() }
        }

        if let error {
          result = .failure(error)
        }

        continuation.resume(with: result)
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
