//
//  EditorModuleCompletion.swift
//
//  Created by cyan on 2/27/23.
//

import Foundation
import NaturalLanguage
import MarkEditCore

public protocol EditorModuleCompletionDelegate: AnyObject {
  func editorCompletion(
    _ sender: EditorModuleCompletion,
    request prefix: String,
    anchor: TextTokenizeAnchor,
    partialRange: NSRange,
    tokenizedWords: [String]
  )

  func editorCompletionDidCommit(_ sender: EditorModuleCompletion)
  func editorCompletionDidCancel(_ sender: EditorModuleCompletion)
  func editorCompletionDidSelectPrevious(_ sender: EditorModuleCompletion)
  func editorCompletionDidSelectNext(_ sender: EditorModuleCompletion)
}

public final class EditorModuleCompletion: NativeModuleCompletion {
  private weak var delegate: EditorModuleCompletionDelegate?
  private var cachedTokens = [String]()

  public init(delegate: EditorModuleCompletionDelegate) {
    self.delegate = delegate
  }

  public func requestCompletions(anchor: TextTokenizeAnchor, fullText: String?) {
    let tokenizer = NLTokenizer(unit: .word)
    tokenizer.string = anchor.text

    let pos = anchor.text.index(anchor.text.startIndex, offsetBy: max(0, anchor.pos - 1))
    let range = tokenizer.tokenRange(at: pos)

    // Figure out the partial word range with one tokenization pass
    let from = range.lowerBound.utf16Offset(in: anchor.text)
    let to = range.upperBound.utf16Offset(in: anchor.text)
    let prefix = anchor.text[range].lowercased().trimmingCharacters(in: .whitespaces)

    // Figure out all words in the document with more tokenization passes
    if let fullText {
      cachedTokens = tokens(in: fullText)
    }

    delegate?.editorCompletion(
      self,
      request: prefix,
      anchor: anchor,
      partialRange: NSRange(location: from, length: to - from),
      tokenizedWords: (cachedTokens + tokens(in: anchor.text)).filter {
        $0.lowercased().hasPrefix(prefix)
      }
    )
  }

  public func commitCompletion() {
    delegate?.editorCompletionDidCommit(self)
  }

  public func cancelCompletion() {
    delegate?.editorCompletionDidCancel(self)
  }

  public func selectPrevious() {
    delegate?.editorCompletionDidSelectPrevious(self)
  }

  public func selectNext() {
    delegate?.editorCompletionDidSelectNext(self)
  }
}

// MARK: - Private

private extension EditorModuleCompletion {
  func tokens(in string: String) -> [String] {
    let tokenizer = NLTokenizer(unit: .word)
    tokenizer.string = string

    let range = string.startIndex..<string.endIndex
    return tokenizer.tokens(for: range).map { String(string[$0]) }
  }
}
