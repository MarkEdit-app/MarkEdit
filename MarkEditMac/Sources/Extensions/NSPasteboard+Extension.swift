//
//  NSPasteboard+Extension.swift
//  MarkEditMac
//
//  Created by cyan on 2024/10/14.
//

import AppKit

extension NSPasteboard {
  func sanitizeDiffs() {
    guard let string, string.contains("{{md-diff-") else {
      return
    }

    overwrite(string: string.replacingOccurrences(
      of: "\u{200B}\\{\\{md-diff-(added|removed)-(\\d+)\\}\\}\u{200B}",
      with: "",
      options: .regularExpression
    ))
  }
}
