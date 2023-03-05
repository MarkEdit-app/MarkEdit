//
//  EditorViewController+Completion.swift
//  MarkEditMac
//
//  Created by cyan on 2/27/23.
//

import AppKit
import NaturalLanguage
import MarkEditCore
import MarkEditKit

extension EditorViewController {
  func requestCompletions(
    prefix: String,
    anchor: TextTokenizeAnchor,
    partialRange: NSRange,
    tokenizedWords: [String]
  ) {
    guard !prefix.isEmpty else {
      return cancelCompletion()
    }

    completionContext.fromIndex = anchor.offset + partialRange.location
    completionContext.toIndex = completionContext.fromIndex + partialRange.length
    var completions = [String]()

    if AppPreferences.Assistant.wordsInDocument {
      // Remove tokens if they "cannot be completed", usually means they are not a word
      let isWord = completions.contains { $0.lowercased() == prefix }
      completions.append(contentsOf: tokenizedWords.filter { isWord || $0.lowercased() != prefix })
    }

    if AppPreferences.Assistant.standardWords {
      completions.append(contentsOf: spellChecker.completions(
        forPartialWordRange: partialRange,
        in: anchor.text,
        language: nil,
        inSpellDocumentWithTag: 0
      ) ?? [])
    }

    if AppPreferences.Assistant.guessedWords {
      completions.append(contentsOf: spellChecker.guesses(
        forWordRange: partialRange,
        in: anchor.text,
        language: nil,
        inSpellDocumentWithTag: 0
      ) ?? [])
    }

    updateCompletionPanel(isVisible: !completions.isEmpty)
    updateCompletionPanel(completions: completions.deduplicated)
  }

  func commitCompletion() {
    bridge.core.insertText(
      text: completionContext.selectedText,
      from: completionContext.fromIndex,
      to: completionContext.toIndex
    )

    cancelCompletion()
  }

  func cancelCompletion() {
    updateCompletionPanel(isVisible: false)
  }
}

// MARK: - Panels

extension EditorViewController {
  func updateCompletionPanel(isVisible: Bool) {
    let changed = completionContext.isPanelVisible != isVisible
    completionContext.isPanelVisible = isVisible

    if changed {
      bridge.completion.setState(panelVisible: isVisible)
    }
  }

  private func updateCompletionPanel(completions: [String]) {
    guard completionContext.isPanelVisible else {
      return
    }

    Task {
      // Get the rectangle at the beginning of the word.
      //
      // For example, for "Hello", we are showing the panel at position relative to letter "H".
      if let caretRect = try? await bridge.selection.getRect(pos: completionContext.fromIndex) {
        updateCompletionPanel(completions: completions, caretRect: caretRect.cgRect)
      }
    }
  }

  private func updateCompletionPanel(completions: [String], caretRect: CGRect) {
    guard completionContext.isPanelVisible, let parentWindow = view.window else {
      return
    }

    completionContext.updateCompletions(
      completions,
      parentWindow: parentWindow,
      caretRect: caretRect
    )
  }
}
