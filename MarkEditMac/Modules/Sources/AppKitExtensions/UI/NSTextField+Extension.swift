//
//  NSTextField+Extension.swift
//
//  Created by cyan on 12/28/22.
//

import AppKit

public extension NSTextField {
  func startEditing(in window: NSWindow?) {
    guard !isFirstResponder(in: window) else {
      return
    }

    window?.makeFirstResponder(self)
  }
}
