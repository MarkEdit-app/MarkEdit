//
//  EditorSelectionHistory.swift
//  MarkEditMac
//
//  Created by cyan on 4/17/26.
//

import Foundation
import MarkEditCore
import MarkEditKit

@MainActor
enum EditorSelectionHistory {
  private static var saveTask: Task<Void, Never>?
  private static var pendingInfo: (range: SelectionRange, fileURL: URL)?

  static func save(info: LineColumnInfo, for fileURL: URL?) {
    guard let range = info.selectionRange, let fileURL else {
      return
    }

    // Store the latest call (last wins)
    pendingInfo = (range, fileURL)

    saveTask?.cancel()
    saveTask = Task {
      try? await Task.sleep(for: .seconds(0.3))
      flushPendingInfo()
    }
  }

  static func selectionRange(for fileURL: URL) -> SelectionRange? {
    let key = fileURL.cacheKey
    guard let entry = EditorHistory.selectionRanges[key] else {
      return nil
    }

    // Update access time to keep the entry fresh
    var current = EditorHistory.selectionRanges
    current[key] = EditorHistory.SelectionRangeEntry(entry.selectionRange)
    EditorHistory.selectionRanges = current
    return entry.selectionRange
  }

  /// Removes selection entries older than the retention period
  static func purgeStaleEntries() {
    // Flush any pending saves before purging
    flushPendingInfo()

    let cutoffDate = Date(timeIntervalSinceNow: -Double(Constants.retentionDays) * 86400)
    var current = EditorHistory.selectionRanges

    let staleEntries = current.filter {
      $0.value.lastAccessed < cutoffDate
    }

    for (key, _) in staleEntries {
      current.removeValue(forKey: key)
    }

    if !staleEntries.isEmpty {
      EditorHistory.selectionRanges = current
    }
  }
}

// MARK: - Private

private extension EditorSelectionHistory {
  enum Constants {
    static let retentionDays = 7
  }

  static func flushPendingInfo() {
    saveTask?.cancel()
    saveTask = nil

    guard let (range, fileURL) = pendingInfo else {
      return
    }

    var current = EditorHistory.selectionRanges
    current[fileURL.cacheKey] = EditorHistory.SelectionRangeEntry(range)
    EditorHistory.selectionRanges = current
    pendingInfo = nil
  }
}

private extension URL {
  var cacheKey: String {
    path(percentEncoded: false)
  }
}
