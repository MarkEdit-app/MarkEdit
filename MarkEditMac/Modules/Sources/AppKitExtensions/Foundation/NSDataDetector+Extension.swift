//
//  NSDataDetector+Extension.swift
//
//  Created by cyan on 1/4/23.
//

import Foundation

public extension NSDataDetector {
  static func extractURL(from string: String) -> String? {
    let range = NSRange(location: 0, length: string.utf16.count)
    let detector = try? Self(types: NSTextCheckingResult.CheckingType.link.rawValue)
    return detector?.firstMatch(in: string, range: range)?.url?.absoluteString
  }
}
