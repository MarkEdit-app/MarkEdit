//
//  NSMenuItem+Extension.swift
//
//  Created by cyan on 12/25/22.
//

import AppKit

public extension NSMenuItem {
  convenience init(title: String) {
    self.init(title: title, action: nil, keyEquivalent: "")
  }

  var copiedItem: NSMenuItem? {
    copy() as? NSMenuItem
  }

  func setOn(_ on: Bool) {
    state = on ? .on : .off
  }

  func toggle() {
    state.toggle()
  }
}

extension NSControl.StateValue {
  mutating func toggle() {
    self = self == .on ? .off : .on
  }
}
