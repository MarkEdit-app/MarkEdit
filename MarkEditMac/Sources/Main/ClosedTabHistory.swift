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
 - `Entry` (persisted): stores path, cursor line, tab index, and standalone flag
 - `windowRefs` (in-memory): weak references to a surviving sibling window in the same tab group

 On reopen, the sibling reference identifies which window group to restore into.
 After restart (or if the sibling is deallocated), falls back to the key window.
 Standalone tabs (tabbedWindows == nil at close time) always reopen as standalone.
 */
@MainActor
final class ClosedTabHistory {
  static let shared = ClosedTabHistory()

  struct ReopenableEntry {
    let url: URL
    let lineNumber: Int?
    let tabIndex: Int?
    let sourceWindow: NSWindow?
    let wasStandalone: Bool
  }

  private let maxEntryCount = 20

  @Storage(key: "general.closed-tab-history", defaultValue: [])
  private var entries: [Entry]

  private var windowRefs: [String: Weak<NSWindow>] = [:]

  private init() {}

  var hasReopenableEntries: Bool {
    let openPaths = openDocumentPaths
    return entries.contains { $0.isReopenable(openPaths: openPaths) }
  }

  func push(_ url: URL, lineNumber: Int?, tabIndex: Int?, sourceWindow: NSWindow?, wasStandalone: Bool) {
    var current = entries
    current.removeAll { $0.path == url.path }
    current.append(Entry(path: url.path, lineNumber: lineNumber, tabIndex: tabIndex, wasStandalone: wasStandalone))

    windowRefs = windowRefs.filter { $0.value.value != nil }

    if let sourceWindow {
      windowRefs[url.path] = Weak(sourceWindow)
    }

    if current.count > maxEntryCount {
      current.removeFirst(current.count - maxEntryCount)
    }

    entries = current
  }

  func pop() -> ReopenableEntry? {
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

      let sourceWindow = windowRefs.removeValue(forKey: entry.path)?.value

      return ReopenableEntry(
        url: URL(fileURLWithPath: entry.path),
        lineNumber: entry.lineNumber,
        tabIndex: entry.tabIndex,
        sourceWindow: sourceWindow,
        wasStandalone: entry.wasStandalone
      )
    }

    entries = current
    return nil
  }
}

// MARK: - Private

private extension ClosedTabHistory {
  struct Entry: Codable {
    let path: String
    let lineNumber: Int?
    let tabIndex: Int?
    let wasStandalone: Bool

    init(path: String, lineNumber: Int?, tabIndex: Int?, wasStandalone: Bool) {
      self.path = path
      self.lineNumber = lineNumber
      self.tabIndex = tabIndex
      self.wasStandalone = wasStandalone
    }

    // Migration: wasStandalone added after initial release, defaults to false for older data
    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      path = try container.decode(String.self, forKey: .path)
      lineNumber = try container.decodeIfPresent(Int.self, forKey: .lineNumber)
      tabIndex = try container.decodeIfPresent(Int.self, forKey: .tabIndex)
      wasStandalone = try container.decodeIfPresent(Bool.self, forKey: .wasStandalone) ?? false
    }

    func isReopenable(openPaths: Set<String>) -> Bool {
      !openPaths.contains(path) && FileManager.default.fileExists(atPath: path)
    }

    func isOrphaned(openPaths: Set<String>) -> Bool {
      !openPaths.contains(path) && !FileManager.default.fileExists(atPath: path)
    }
  }

  struct Weak<T: AnyObject> {
    weak var value: T?

    init(_ value: T) { self.value = value }
  }

  var openDocumentPaths: Set<String> {
    Set(NSDocumentController.shared.documents.compactMap { $0.fileURL?.path })
  }
}
