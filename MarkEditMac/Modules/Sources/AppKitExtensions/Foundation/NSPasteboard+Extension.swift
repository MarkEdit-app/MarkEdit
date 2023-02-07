//
//  NSPasteboard+Extension.swift
//
//  Created by cyan on 1/4/23.
//

import AppKit

public extension NSPasteboard {
  var string: String? {
    string(forType: .string)
  }

  var url: String? {
    guard let string else {
      return nil
    }

    return NSDataDetector.extractURL(from: string)
  }

  func overwrite(string: String?) {
    clearContents()

    if let string {
      setString(string, forType: .string)
    }
  }
}
