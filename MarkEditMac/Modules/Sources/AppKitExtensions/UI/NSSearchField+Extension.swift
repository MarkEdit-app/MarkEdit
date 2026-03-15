//
//  NSSearchField+Extension.swift
//
//  Created by cyan on 12/19/22.
//

import AppKit

public extension NSSearchField {
  var clipView: NSView? {
    // [macOS 26] Revisit this later (#1281)
    for view in subviews where view.className.hasSuffix("FocusClipView") {
      // _NSKeyboardFocusClipView
      return view
    }

    return nil
  }

  var modernBezelView: NSView? {
    firstDescendant {
      $0.className.contains("AppKitSearchField")
    }
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
