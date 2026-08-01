//
//  Text+Extension.swift
//
//  Created by cyan on 7/31/26.
//

import SwiftUI

public extension Text {
  /// Plain text, tinting occurrences of `query` only when there's something to highlight.
  init(_ text: String, highlighting query: String, color: Color = .mint) {
    if query.isEmpty {
      self.init(text)
    } else {
      self.init(AttributedString(text, highlighting: query, color: color))
    }
  }
}

// MARK: - Private

private extension AttributedString {
  /// Creates a string with every case-insensitive occurrence of `query` tinted.
  init(_ text: String, highlighting query: String, color: Color) {
    self.init(text)
    guard !query.isEmpty else {
      return
    }

    var start = startIndex
    while let range = self[start...].range(of: query, options: .caseInsensitive, locale: .current) {
      self[range].foregroundColor = .primary
      self[range].backgroundColor = color.opacity(0.2)
      self[range].underlineStyle = Text.LineStyle(pattern: .solid, color: color)
      start = range.upperBound
    }
  }
}
