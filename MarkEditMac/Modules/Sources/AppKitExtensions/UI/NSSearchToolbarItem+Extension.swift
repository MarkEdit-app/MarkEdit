//
//  NSSearchToolbarItem+Extension.swift
//
//  Created by cyan on 7/19/26.
//

import AppKit

public extension NSSearchToolbarItem {
  var minimumSearchFieldWidth: Double {
    get {
      let selector = "minimumWidthForSearchFieldRepresentation"
      if responds(to: sel_getUid(selector)) {
        return value(forKey: selector) as? Double ?? 0
      }

      assertionFailure("Invalid selector: \(selector)")
      return 0
    }
    set {
      let selector = sel_getUid("setMinimumWidthForSearchFieldRepresentation:")
      if responds(to: selector) {
        perform(selector, with: newValue)
      } else {
        assertionFailure("Invalid selector: \(selector)")
      }
    }
  }
}
