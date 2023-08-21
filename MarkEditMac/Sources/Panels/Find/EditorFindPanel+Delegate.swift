//
//  EditorFindPanel+Delegate.swift
//  MarkEditMac
//
//  Created by cyan on 12/25/22.
//

import AppKit

// MARK: - NSSearchFieldDelegate

extension EditorFindPanel: NSSearchFieldDelegate {
  func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
    switch (selector, mode) {
    case (#selector(insertTab(_:)), .replace):
      // Focus on the replace panel
      delegate?.editorFindPanelDidPressTabKey(self, isBacktab: false)
      return true
    case (#selector(insertBacktab(_:)), _):
      delegate?.editorFindPanelDidPressTabKey(self, isBacktab: true)
      return true
    case (#selector(insertNewline(_:)), _):
      // Navigate between search results
      if NSApplication.shared.shiftKeyIsPressed {
        delegate?.editorFindPanelDidClickPrevious(self)
      } else {
        delegate?.editorFindPanelDidClickNext(self)
      }
      return true
    default:
      return false
    }
  }
}
