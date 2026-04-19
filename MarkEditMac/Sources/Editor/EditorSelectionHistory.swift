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
  private static var pendingInfo: (range: SelectionRange, fileURL: URL, fileSize: Int)?

  static func save(info: LineColumnInfo, for fileURL: URL?) {
    guard let range = info.selectionRange, let fileURL else {
      return
    }

    // Store the latest call (last wins)
    pendingInfo = (range, fileURL, info.contentLength)

    saveTask?.cancel()
    saveTask = Task {
      try? await Task.sleep(for: .seconds(0.3))
      flushPendingInfo()
    }
  }

  static func selectionRange(for fileURL: URL, fileSize: Int?) -> SelectionRange? {
    let key = fileURL.cacheKey
    guard let entry = EditorHistory.selectionRanges[key] else {
      return nil
    }

    // Discard if the content length changed, the file was likely externally edited
    if let fileSize, entry.fileSize != fileSize {
      discard(for: fileURL)
      return nil
    }

    // Update access time to keep the entry fresh
    Task {
      var current = EditorHistory.selectionRanges
      current[key] = EditorHistory.SelectionRangeEntry(entry.selectionRange, fileSize: entry.fileSize)
      EditorHistory.selectionRanges = current
    }

    return entry.selectionRange
  }

  static func discard(for fileURL: URL) {
    if pendingInfo?.fileURL == fileURL {
      saveTask?.cancel()
      saveTask = nil
      pendingInfo = nil
    }

    Task {
      var current = EditorHistory.selectionRanges
      current.removeValue(forKey: fileURL.cacheKey)
      EditorHistory.selectionRanges = current
    }
  }

  /// Removes selection entries older than the retention period and enforces a maximum entry limit
  static func purgeStaleEntries() {
    // Flush any pending saves before purging
    flushPendingInfo()

    let cutoffDate = Date(timeIntervalSinceNow: -Double(Constants.retentionDays) * 86400)
    var current = EditorHistory.selectionRanges
    var hasChanges = false

    let staleEntries = current.filter {
      $0.value.lastAccessed < cutoffDate
    }

    // Remove stale entries older than retention period
    for (key, _) in staleEntries {
      current.removeValue(forKey: key)
      hasChanges = true
    }

    // Enforce max entry limit by removing oldest accessed
    if current.count > Constants.maxEntries {
      let sortedEntries = current.sorted {
        $0.value.lastAccessed < $1.value.lastAccessed
      }

      for (key, _) in sortedEntries.prefix(current.count - Constants.maxEntries) {
        current.removeValue(forKey: key)
      }

      hasChanges = true
    }

    if hasChanges {
      EditorHistory.selectionRanges = current
    }
  }
}

// MARK: - Private

private extension EditorSelectionHistory {
  enum Constants {
    static let retentionDays = 7
    static let maxEntries = 50
  }

  static func flushPendingInfo() {
    saveTask?.cancel()
    saveTask = nil

    guard let (range, fileURL, fileSize) = pendingInfo else {
      return
    }

    var current = EditorHistory.selectionRanges
    current[fileURL.cacheKey] = EditorHistory.SelectionRangeEntry(range, fileSize: fileSize)
    EditorHistory.selectionRanges = current
    pendingInfo = nil
  }
}

private extension URL {
  var cacheKey: String {
    path(percentEncoded: false)
  }
}
