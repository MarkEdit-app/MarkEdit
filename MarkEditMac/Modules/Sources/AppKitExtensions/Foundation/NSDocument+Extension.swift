//
//  NSDocument+Extension.swift
//
//  Created by cyan on 1/21/23.
//

import AppKit

public extension NSDocument {
  var folderURL: URL? {
    fileURL?.deletingLastPathComponent()
  }

  /// Continue on the main actor even while AppKit is synchronously waiting for document work.
  /// Unlike a main-queue dispatch, this uses AppKit's mechanism for interrupting that wait.
  nonisolated func continueAsynchronousWorkOnMainActor(_ body: @Sendable @MainActor @escaping () -> Void) {
    continueAsynchronousWorkOnMainThread {
      // AppKit guarantees this callback runs on the main thread, but its signature lacks actor isolation
      MainActor.assumeIsolated(body)
    }
  }

  /// Returns the file's bytes if they match the document's current serialized content; otherwise nil.
  var matchingFileData: Data? {
    get throws {
      guard let fileURL, let fileType else {
        return nil
      }

      let diskData = try Data(contentsOf: fileURL)
      return diskData == (try data(ofType: fileType)) ? diskData : nil
    }
  }

  func markContentDirty(_ isDirty: Bool) {
    // The undo stack is implemented in CoreEditor entirely,
    // there are only two meaningful change count values: 0 (saved) or 1 (dirty).
    updateChangeCount(isDirty ? .changeDone : .changeCleared)
  }

  func otherVersions(olderThanDays days: Int) -> [NSFileVersion] {
    guard let url = fileURL else {
      return []
    }

    guard let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: .now) else {
      return []
    }

    let all = NSFileVersion.otherVersionsOfItem(at: url) ?? []
    return days == 0 ? all : all.filter {
      ($0.modificationDate ?? .distantFuture) < cutoffDate
    }
  }

  func otherVersions(olderThanMaxLength maxLength: Int) -> [NSFileVersion] {
    guard let url = fileURL else {
      return []
    }

    let all = NSFileVersion.otherVersionsOfItem(at: url) ?? []
    let sorted = all.sorted {
      ($0.modificationDate ?? .distantPast) > ($1.modificationDate ?? .distantPast)
    }

    return maxLength > (sorted.count - 1) ? [] : Array(sorted.suffix(from: maxLength))
  }
}
