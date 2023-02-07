//
//  LineEndings+Extension.swift
//
//  Created by cyan on 1/28/23.
//

import Foundation

public extension LineEndings {
  var characters: String {
    if self == .crlf {
      return "\r\n"
    } else if self == .cr {
      return "\r"
    } else {
      // LF is the preferred line endings on modern macOS
      return "\n"
    }
  }
}
