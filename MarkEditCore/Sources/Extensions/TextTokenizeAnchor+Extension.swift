//
//  TextTokenizeAnchor+Extension.swift
//
//  Created by cyan on 11/9/23.
//

import Foundation

public extension TextTokenizeAnchor {
  var afterSpace: Bool {
    guard pos > 0 else {
      return false
    }

    return text[text.utf16.index(text.startIndex, offsetBy: pos - 1)] == " "
  }
}
