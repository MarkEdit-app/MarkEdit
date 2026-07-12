//
//  String+Extension.swift
//
//  Created by cyan on 7/12/26.
//

import Foundation

public extension String {
  /// Lowercases and collapses runs of non-alphanumerics into single dashes, e.g. "Foo Bar!" -> "foo-bar".
  var kebabCased: String {
    lowercased()
      .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
      .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
  }

  /// Shortens an overly long string for display, keeping the head and tail joined by an ellipsis.
  func truncatedForDisplay(maxLength: UInt = 60) -> String {
    guard count > maxLength else {
      return self
    }

    let ellipsis = "\u{2026}"
    let headCount = Int(maxLength) * 2 / 3
    let tailCount = Int(maxLength) - headCount - ellipsis.count
    return "\(prefix(headCount))\(ellipsis)\(suffix(tailCount))"
  }
}
