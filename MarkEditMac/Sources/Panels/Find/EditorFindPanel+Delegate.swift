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
    case (#selector(moveUp(_:)), _, _):
      // Move the caret up, or browse to an older recent search at the boundary
      return navigateRecentSearches(textView: textView, forward: false)
    case (#selector(moveDown(_:)), _, _):
      // Move the caret down, or browse to a newer recent search at the boundary
      return navigateRecentSearches(textView: textView, forward: true)
    case (#selector(cancelOperation(_:)), _, _):
      delegate?.editorFindPanel(self, modeDidChange: .hidden)
      return true
    default:
      return false
    }
  }
}

// MARK: - Private

private extension EditorFindPanel {
  /// Browse recent searches once the caret reaches the boundary, returns true when handled.
  ///
  /// The cursor is self-validating: trusted only while it matches the field, otherwise re-seeded.
  func navigateRecentSearches(textView: NSTextView, forward: Bool) -> Bool {
    let selectedRange = textView.selectedRange()
    let length = textView.string.utf16.count

    // Up only at the start position, down only at the end position
    if forward {
      guard selectedRange.length == 0 && selectedRange.location == length else {
        return false
      }
    } else {
      guard selectedRange.length == 0 && selectedRange.location == 0 else {
        return false
      }
    }

    let recents = searchField.recentSearches
    guard !recents.isEmpty else {
      NSSound.beep()
      return true
    }

    // Trust the cursor only while it still matches the field, otherwise seed from the live input
    let newCursor: Int
    let currentCursor: Int = {
      let stringValue = searchField.stringValue
      if let cursor = recentSearchesCursor, recents.indices.contains(cursor), recents[cursor] == stringValue {
        return cursor
      }

      return recents.firstIndex(of: stringValue) ?? -1
    }()

    if forward {
      // Newer, towards the front of the list
      guard currentCursor > 0 else {
        NSSound.beep()
        return true
      }

      newCursor = currentCursor - 1
    } else {
      // Older, towards the back of the list
      newCursor = Swift.min(currentCursor + 1, recents.count - 1)
      guard newCursor != currentCursor else {
        NSSound.beep()
        return true
      }
    }

    recentSearchesCursor = newCursor
    applyRecentSearch(recents[newCursor], textView: textView, caretAtEnd: forward)
    return true
  }

  /// Set the field to a history entry and kick a search without touching the history.
  func applyRecentSearch(_ value: String, textView: NSTextView, caretAtEnd: Bool) {
    searchField.stringValue = value

    // Keep the caret at the boundary so repeated presses keep browsing
    let selectedRange = NSRange(location: caretAtEnd ? value.utf16.count : 0, length: 0)
    textView.setSelectedRange(selectedRange)

    // Browsing history must not reorder the recents stack
    delegate?.editorFindPanel(self, searchTermDidChange: value, addToRecents: false)
  }
}
