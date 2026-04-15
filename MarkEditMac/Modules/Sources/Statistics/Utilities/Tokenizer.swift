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
  static func count(text: String, unit: NLTokenUnit) -> Int {
    let tokenizer = NLTokenizer(unit: unit)
    tokenizer.string = text

    let tokens = tokenizer.tokens(for: text.startIndex..<text.endIndex)
    return tokens.count
  }

  /// Count CJK characters and CJK punctuation (汉字 + 中文标点).
  static func countCJK(text: String) -> Int {
    var count = 0
    for scalar in text.unicodeScalars {
      let v = scalar.value
      if (0x4E00...0x9FFF).contains(v)       // CJK Unified Ideographs
        || (0x3400...0x4DBF).contains(v)      // CJK Extension A
        || (0x20000...0x2A6DF).contains(v)    // CJK Extension B
        || (0x3000...0x303F).contains(v)      // CJK Symbols and Punctuation
        || (0xFF01...0xFF60).contains(v)      // Fullwidth Forms
        || (0xFE30...0xFE4F).contains(v)      // CJK Compatibility Forms
        || (0x2018...0x201F).contains(v)      // Quotation marks
        || v == 0x2014                         // Em dash —
        || v == 0x2013                         // En dash –
        || v == 0x2026 {                       // Ellipsis …
        count += 1
      }
    }
    return count
  }
}
