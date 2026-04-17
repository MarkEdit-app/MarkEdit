//
//  ClosedTabHistory.swift
//  MarkEditMac
//
//  Created by lamchau on 4/16/26.
//

import AppKit

/**
 Tracks recently closed document URLs for "Reopen Closed Tab" (Cmd+Shift+T).

 Tab restoration requires capturing state at multiple points in the close lifecycle:
 - `windowShouldClose`: captures tab index and sibling window (before tab group membership is lost)
 - `EditorDocument.close()`: persists to history (after save completes, before window deallocation)

 Window targeting uses a two-layer approach:
 - `ClosedTab` (persisted): stores bookmark data, tab index, and standalone flag
 - `windowRefs` (in-memory): weak references to a surviving sibling window in the same tab group

 On reopen, the sibling reference identifies which window group to restore into.
 After restart (or if the sibling is deallocated), falls back to the key window.
 Standalone tabs (no siblings at close time) always reopen as standalone.
 */
@MainActor
final class ClosedTabHistory {
  static let shared = ClosedTabHistory()

  struct RestoredTab {
    let url: URL
    let tabIndex: Int?
    let sourceWindow: NSWindow?
    let wasStandalone: Bool
  }

  private let maxEntryCount = 20

  @Storage(key: "general.closed-tab-history", defaultValue: [])
  private var entries: [ClosedTab]

  private let windowRefs = NSMapTable<NSString, NSWindow>.strongToWeakObjects()

  private init() {}

  var hasReopenableEntries: Bool {
    let openPaths = openDocumentPaths
    return entries.contains { $0.isReopenable(openPaths: openPaths) }
  }

  func push(_ url: URL, tabIndex: Int?, sourceWindow: NSWindow?, wasStandalone: Bool) {
    let path = url.path(percentEncoded: false)

    guard let bookmark = try? url.bookmarkData(
      options: .minimalBookmark,
      includingResourceValuesForKeys: nil,
      relativeTo: nil
    ) else {
      return
    }

    var current = entries
    current.removeAll { $0.resolvedPath == path }
    current.append(ClosedTab(bookmark: bookmark, tabIndex: tabIndex, wasStandalone: wasStandalone))

    if let sourceWindow {
      windowRefs.setObject(sourceWindow, forKey: path as NSString)
    }

    if current.count > maxEntryCount {
      current.removeFirst(current.count - maxEntryCount)
    }

    entries = current
  }

  func pop() -> RestoredTab? {
    var current = entries
    let openPaths = openDocumentPaths

    for index in current.indices.reversed() {
      let entry = current[index]

      guard entry.isReopenable(openPaths: openPaths) else {
        if entry.isOrphaned(openPaths: openPaths) {
          current.remove(at: index)
        }
        continue
      }

      current.remove(at: index)
      entries = current

      guard let url = entry.resolvedURL else {
        continue
      }

      let path = url.path(percentEncoded: false) as NSString
      let sourceWindow = windowRefs.object(forKey: path)
      windowRefs.removeObject(forKey: path)

      return RestoredTab(
        url: url,
        tabIndex: entry.tabIndex,
        sourceWindow: sourceWindow,
        wasStandalone: entry.wasStandalone ?? false
      )
    }

    entries = current
    return nil
  }
}

// MARK: - Private

private extension ClosedTabHistory {
  struct ClosedTab: Codable {
    let bookmark: Data
    let tabIndex: Int?
    let wasStandalone: Bool?

    var resolvedURL: URL? {
      var isStale = false
      return try? URL(
        resolvingBookmarkData: bookmark,
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      )
    }

    var resolvedPath: String? {
      resolvedURL?.path(percentEncoded: false)
    }

    func isReopenable(openPaths: Set<String>) -> Bool {
      guard let path = resolvedPath else {
        return false
      }

      return !openPaths.contains(path) && FileManager.default.isReadableFile(atPath: path)
    }

    func isOrphaned(openPaths: Set<String>) -> Bool {
      guard let path = resolvedPath else {
        return true
      }

      return !openPaths.contains(path) && !FileManager.default.isReadableFile(atPath: path)
    }
  }

  var openDocumentPaths: Set<String> {
    Set(NSDocumentController.shared.documents.compactMap { $0.fileURL?.path(percentEncoded: false) })
  }
}
