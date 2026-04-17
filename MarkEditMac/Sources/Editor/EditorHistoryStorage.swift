//
//  EditorHistoryStorage.swift
//  MarkEditMac
//
//  Created by cyan on 4/17/26.
//

import Foundation
import MarkEditCore

enum EditorHistory {
  struct ClosedTab: Codable {
    let bookmark: Data
    let tabIndex: Int?
    let wasStandalone: Bool?
  }

  struct SelectionRangeEntry: Codable {
    let selectionRange: SelectionRange
    let lastAccessed: Date

    init(_ selectionRange: SelectionRange) {
      self.selectionRange = selectionRange
      self.lastAccessed = .now
    }
  }

  @Storage(key: "editor-history.closed-tabs", defaultValue: [])
  static var closedTabs: [ClosedTab]

  @Storage(key: "editor-history.selection-ranges", defaultValue: [:])
  static var selectionRanges: [String: SelectionRangeEntry]
}
