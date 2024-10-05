//
//  EditorMainMenu.swift
//  MarkEditMac
//
//  Created by cyan on 2024/10/5.
//

import Foundation
import MarkEditKit

/**
 User defined menu that will be added to the main menu bar.
 */
struct EditorMainMenu: Equatable {
  static let uniquePrefix = "[USER_DEFINED]"

  let menuID: String
  let title: String
  let items: [WebMenuItem]

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.menuID == rhs.menuID
  }
}
