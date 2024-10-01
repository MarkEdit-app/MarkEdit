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

  func addToRecents(searchTerm: String) {
    guard !searchTerm.isEmpty else {
      return
    }

    let recents = recentSearches.filter { $0 != searchTerm }
    recentSearches = [searchTerm] + recents
  }

  func setIconTintColor(_ tintColor: NSColor?) {
    guard let buttonCell = (cell as? NSSearchFieldCell)?.searchButtonCell else {
      return
    }

    guard let iconImage = buttonCell.image else {
      return
    }

    guard iconImage.responds(to: sel_getUid("_setTintColor:")) else {
      return
    }

    iconImage.perform(sel_getUid("_setTintColor:"), with: tintColor)
    buttonCell.image = iconImage
    needsDisplay = true
  }
}
