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
    let sorted = all.newestToOldest(throttle: false)
    return maxLength > (sorted.count - 1) ? [] : Array(sorted.suffix(from: maxLength))
  }
}
