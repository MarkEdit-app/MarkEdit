//
//  NSScrollView+Extension.swift
//
//  Created by cyan on 10/17/24.
//

import AppKit

public extension NSScrollView {
  var textView: NSTextView? {
    documentView as? NSTextView
  }

  func scrollTextViewDown() {
    textView?.scrollPageDown(nil)
  }

  func scrollTextViewUp() {
    textView?.scrollPageUp(nil)
  }

  func setContentOffset(_ offset: CGPoint) {
    contentView.scroll(to: offset)
  }

  func setAttributedText(_ text: NSAttributedString) {
    textView?.textStorage?.setAttributedString(text)
  }
}
