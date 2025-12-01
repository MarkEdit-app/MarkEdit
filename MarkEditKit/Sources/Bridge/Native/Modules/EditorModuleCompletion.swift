//
//  EditorModuleCompletion.swift
//
//  Created by cyan on 2/27/23.
//

import Foundation
import NaturalLanguage
import MarkEditCore

@MainActor
public protocol EditorModuleCompletionDelegate: AnyObject {
  func editorCompletion(
    _ sender: EditorModuleCompletion,
    request prefix: String,
    anchor: TextTokenizeAnchor,
    partialRange: NSRange,
    tokenizedWords: [String]
  )

  func editorCompletionTokenizeWholeDocument(_ sender: EditorModuleCompletion) -> Bool
  func editorCompletionDidCommit(_ sender: EditorModuleCompletion, insert: String?)
  func editorCompletionDidCancel(_ sender: EditorModuleCompletion)
  func editorCompletionDidSelectPrevious(_ sender: EditorModuleCompletion)
  func editorCompletionDidSelectNext(_ sender: EditorModuleCompletion)
  func editorCompletionDidSelectTop(_ sender: EditorModuleCompletion)
  func editorCompletionDidSelectBottom(_ sender: EditorModuleCompletion)
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

    let pos = anchor.text.utf16.index(anchor.text.startIndex, offsetBy: max(0, anchor.pos - 1))
    let range = tokenizer.tokenRange(at: pos)

    // Figure out the partial word range with one tokenization pass
    let from = range.lowerBound.utf16Offset(in: anchor.text)
    let to = range.upperBound.utf16Offset(in: anchor.text)

    // When the trimmed prefix is empty and the caret is after a space,
    // use " " to complete the partial range as a sentence.
    let prefix = {
      let trimmed = anchor.text[range].trimmingCharacters(in: .whitespaces)
      return trimmed.isEmpty && anchor.afterSpace ? " " : trimmed
    }()

    // Figure out all words in the document with more tokenization passes
    if let fullText, delegate?.editorCompletionTokenizeWholeDocument(self) == true {
      cachedTokens = tokens(in: fullText)
    }

    delegate?.editorCompletion(
      self,
      request: prefix,
      anchor: anchor,
      partialRange: NSRange(location: from, length: to - from),
      tokenizedWords: (cachedTokens + tokens(in: anchor.text)).filter {
        $0.hasPrefixIgnoreCase(prefix)
      }
    )
  }

  public func commitCompletion(insert: String?) {
    delegate?.editorCompletionDidCommit(self, insert: insert)
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

  public func selectTop() {
    delegate?.editorCompletionDidSelectTop(self)
  }

  public func selectBottom() {
    delegate?.editorCompletionDidSelectBottom(self)
  }
}

// MARK: - Private

private extension EditorModuleCompletion {
  func tokens(in string: String) -> [String] {
    let tokenizer = NLTokenizer(unit: .word)
    tokenizer.string = string

    let range = string.startIndex..<string.endIndex
    return tokenizer.tokens(for: range).map { String(string[$0]) }.deduplicated
  }
}
