//
//  NSApplication+Extension.swift
//  MarkEditMac
//
//  Created by cyan on 12/13/22.
//

import AppKit
import MarkEditKit

extension NSApplication {
  var appDelegate: AppDelegate? {
    guard let delegate = delegate as? AppDelegate else {
      Logger.assert(delegate != nil, "Expected to get AppDelegate")
      return nil
    }

    return delegate
  }

  var currentEditor: EditorViewController? {
    if let editor = keyWindow?.contentViewController as? EditorViewController {
      return editor
    }

    return mainWindow?.contentViewController as? EditorViewController
  }
}
