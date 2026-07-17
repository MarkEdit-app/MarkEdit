//
//  NSTextField+Extension.swift
//
//  Created by cyan on 12/28/22.
//

import AppKit

public extension NSTextField {
  static var alertCapableTextField: Self {
    Self(frame: CGRect(x: 0, y: 0, width: 256, height: 22))
  }

  func startEditing(in window: NSWindow?, alwaysRefocus: Bool = false) {
    guard alwaysRefocus || !isFirstResponder(in: window) else {
      return
    }

    window?.makeFirstResponder(self)
  }

  func selectAll() {
    currentEditor()?.selectAll(self)
  }
}
