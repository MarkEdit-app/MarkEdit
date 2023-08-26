//
//  Tokenizer.swift
//
//  Created by cyan on 8/26/23.
//

import Foundation
import NaturalLanguage

enum Tokenizer {
  struct Result {
    let words: Int
    let sentences: Int
    let paragraphs: Int
  }

  static func tokenize(text: String) -> Result {
    Result(
      words: tokenize(text: text, unit: .word),
      sentences: tokenize(text: text, unit: .sentence),
      paragraphs: tokenize(text: text, unit: .paragraph)
    )
  }
}

// MARK: - Private

private extension Tokenizer {
  static func tokenize(text: String, unit: NLTokenUnit) -> Int {
    let tokenizer = NLTokenizer(unit: unit)
    tokenizer.string = text

    let tokens = tokenizer.tokens(for: text.startIndex..<text.endIndex)
    return tokens.count
  }
}
