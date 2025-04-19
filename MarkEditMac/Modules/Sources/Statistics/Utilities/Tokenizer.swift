//
//  Tokenizer.swift
//
//  Created by cyan on 8/26/23.
//

import Foundation
import NaturalLanguage

/**
 NLP based tokenizer to count words, sentences, etc.
 */
enum Tokenizer {
  struct Result {
    let characters: Int
    let words: Int
    let sentences: Int
    let paragraphs: Int
    let comments: Int
  }

  static func tokenize(sourceText: String, trimmedText: String, commentCount: Int) -> Result {
    Result(
      characters: sourceText.count, // Always use full text for characters
      words: tokenize(text: trimmedText, unit: .word),
      sentences: tokenize(text: trimmedText, unit: .sentence),
      paragraphs: tokenize(text: trimmedText, unit: .paragraph),
      comments: commentCount
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
