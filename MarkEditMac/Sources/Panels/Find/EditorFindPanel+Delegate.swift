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
    if selector == #selector(insertTab(_:)) && mode == .replace {
      // Focus on the replace panel
      delegate?.editorFindPanelDidPressTabKey(self)
      return true
    } else if selector == #selector(insertNewline(_:)) {
      // Navigate between search results
      if NSApplication.shared.shiftKeyIsPressed {
        delegate?.editorFindPanelDidClickPrevious(self)
      } else {
        delegate?.editorFindPanelDidClickNext(self)
      }

      return true
    }

    return false
  }
}
