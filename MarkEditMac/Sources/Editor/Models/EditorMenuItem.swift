//
//  EditorMenuItem.swift
//  MarkEditMac
//
//  Created by cyan on 10/5/24.
//

import Foundation
import MarkEditKit

/**
 User defined menu that will be added to the main menu bar.
 */
struct EditorMenuItem: Equatable {
  static let uniquePrefix = "userDefinedMenuItem"
  static let specialDivider = "extensionsMenuDivider"

  let id: String
  let item: WebMenuItem

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }
}
