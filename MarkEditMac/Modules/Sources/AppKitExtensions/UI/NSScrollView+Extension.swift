//
//  NSScrollView+Extension.swift
//
//  Created by cyan on 2024/10/17.
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
    textView?.textContentStorage?.attributedString = text
  }
}
