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
    switch (selector, mode, NSApp.isFullKeyboardAccessEnabled) {
    case (#selector(insertTab(_:)), .replace, false):
      // Focus on the replace panel
      delegate?.editorFindPanelDidPressTabKey(self, isBacktab: false)
      return true
    case (#selector(insertBacktab(_:)), _, false):
      delegate?.editorFindPanelDidPressTabKey(self, isBacktab: true)
      return true
    case (#selector(insertNewline(_:)), _, _):
      // Navigate between search results
      if NSApplication.shared.shiftKeyIsPressed {
        delegate?.editorFindPanelDidClickPrevious(self)
      } else {
        delegate?.editorFindPanelDidClickNext(self)
      }
      return true
    case (#selector(cancelOperation(_:)), _, _):
      delegate?.editorFindPanel(self, modeDidChange: .hidden)
      return true
    default:
      return false
    }
  }
}
