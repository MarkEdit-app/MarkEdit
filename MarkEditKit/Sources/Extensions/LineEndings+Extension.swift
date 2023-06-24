//
//  LineEndings+Extension.swift
//
//  Created by cyan on 1/28/23.
//

import Foundation

public extension LineEndings {
  var characters: String {
    switch self {
    case .crlf:
      return "\r\n"
    case .cr:
      return "\r"
    default:
      // LF is the preferred line endings on modern macOS
      return "\n"
    }
  }
}
