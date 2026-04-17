//
//  EditorHistoryStorage.swift
//  MarkEditMac
//
//  Created by cyan on 4/17/26.
//

import Foundation

enum EditorHistory {
  struct ClosedTab: Codable {
    let bookmark: Data
    let tabIndex: Int?
    let wasStandalone: Bool?
  }

  @Storage(key: "editor-history.closed-tabs", defaultValue: [])
  static var closedTabs: [ClosedTab]
}
