//
//  EditorModuleTokenizer.swift
//
//  Created by cyan on 2/23/23.
//

import Foundation
import NaturalLanguage
import MarkEditCore

public final class EditorModuleTokenizer: NativeModuleTokenizer {
  public init() {}

  public func tokenize(anchor: TextTokenizeAnchor) async -> [String: Any] {
    let tokenizer = NLTokenizer(unit: .word)
    tokenizer.string = anchor.text

    let pos = anchor.text.utf16.index(anchor.text.startIndex, offsetBy: anchor.pos)
    let bounds = bounds(in: tokenizer.tokenRange(at: pos), text: anchor.text)

    // Always select at least one character
    return ["from": bounds.lower, "to": max(bounds.upper, bounds.lower + 1)]
  }

  public func moveWordBackward(anchor: TextTokenizeAnchor) async -> Int {
    if let location = (locations(in: anchor.text).last { $0 < anchor.pos }) {
      return location + anchor.offset
    }

    // Failed to tokenize, but we can move by one character instead
    return anchor.pos + anchor.offset - 1
  }

  public func moveWordForward(anchor: TextTokenizeAnchor) async -> Int {
    if let location = (locations(in: anchor.text).first { $0 > anchor.pos }) {
      return location + anchor.offset
    }

    // Failed to tokenize, but we can move by one character instead
    return anchor.pos + anchor.offset + 1
  }
}

// MARK: - Private

private extension EditorModuleTokenizer {
  func locations(in text: String) -> [Int] {
    let tokenizer = NLTokenizer(unit: .word)
    tokenizer.string = text

    let range = text.startIndex..<text.endIndex
    return tokenizer.tokens(for: range).reduce(into: [Int]()) { result, range in
      let bounds = bounds(in: range, text: text)
      result.append(contentsOf: [bounds.lower, bounds.upper])
    }
  }

  func bounds(in range: Range<String.Index>, text: String) -> (lower: Int, upper: Int) {
    (range.lowerBound.utf16Offset(in: text), range.upperBound.utf16Offset(in: text))
  }
}
