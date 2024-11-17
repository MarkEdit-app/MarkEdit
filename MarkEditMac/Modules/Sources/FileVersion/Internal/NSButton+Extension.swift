//
//  NSButton+Extension.swift
//
//  Created by cyan on 10/17/24.
//

import AppKit

extension NSButton {
  func setTitle(_ title: String, font: NSFont = .systemFont(ofSize: 12)) {
    attributedTitle = NSAttributedString(
      string: title,
      attributes: [.font: font]
    )
  }
}
