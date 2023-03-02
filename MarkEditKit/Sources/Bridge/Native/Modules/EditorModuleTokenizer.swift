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

  public func tokenize(anchor: TextTokenizeAnchor) async -> TextTokenizeResult {
    let tokenizer = NLTokenizer(unit: .word)
    tokenizer.string = anchor.text

    let pos = anchor.text.index(anchor.text.startIndex, offsetBy: anchor.pos)
    let range = tokenizer.tokenRange(at: pos)

    let from = range.lowerBound.utf16Offset(in: anchor.text)
    let to = range.upperBound.utf16Offset(in: anchor.text)

    // Always select at least one character
    return TextTokenizeResult(from: from, to: max(to, from + 1))
  }
}
