//
//  NSSearchField+Extension.swift
//
//  Created by cyan on 12/19/22.
//

import AppKit

public extension NSSearchField {
  var clipView: NSView? {
    // _NSKeyboardFocusClipView
    subviews.first { $0.className.hasSuffix("FocusClipView") }
  }

  var searchButtonCell: NSButtonCell? {
    (cell as? NSSearchFieldCell)?.searchButtonCell
  }

  var cancelButtonCell: NSButtonCell? {
    (cell as? NSSearchFieldCell)?.cancelButtonCell
  }

  func addToRecents(searchTerm: String) {
    guard !searchTerm.isEmpty else {
      return
    }

    let recents = recentSearches.filter { $0 != searchTerm }
    recentSearches = [searchTerm] + recents
  }
}
