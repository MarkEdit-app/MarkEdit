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
    guard !prefix.isEmpty || anchor.afterSpace else {
      return cancelCompletion()
    }

    completionContext.fromIndex = anchor.offset + (anchor.afterSpace ? 1 : 0) + partialRange.location
    completionContext.toIndex = completionContext.fromIndex + partialRange.length
    var completions = [String]()

    document?.prepareSpellDocTag()
    let spellDocTag = document?.spellDocTag ?? 0

    // Explicitly do some harmless updates
    spellChecker.automaticallyIdentifiesLanguages = true
    spellChecker.updatePanels()

    if AppPreferences.Assistant.wordsInDocument {
      // Remove tokens if they are exactly the same as the typing prefix
      completions.append(contentsOf: tokenizedWords.filter { $0 != prefix })
    }

    if AppPreferences.Assistant.standardWords {
      completions.append(contentsOf: spellChecker.completions(
        forPartialWordRange: partialRange,
        in: anchor.text,
        language: nil,
        inSpellDocumentWithTag: spellDocTag
      ) ?? [])
    }

    if AppPreferences.Assistant.guessedWords {
      completions.append(contentsOf: spellChecker.guesses(
        forWordRange: partialRange,
        in: anchor.text,
        language: nil,
        inSpellDocumentWithTag: spellDocTag
      ) ?? [])

      // Misspelled correction as a guess
      if let correction = spellChecker.correction(
        forWordRange: partialRange,
        in: anchor.text,
        language: "",
        inSpellDocumentWithTag: spellDocTag
      ) {
        completions.append(correction)
      }
    }

    // If there is an exact match, always make it the first element
    if let index = completions.firstIndex(of: prefix), index > 0 {
      completions.insert(completions.remove(at: index), at: 0)
    }

    updateCompletionPanel(isVisible: !completions.isEmpty)
    updateCompletionPanel(completions: completions.deduplicated, query: prefix)

    if completions.isEmpty {
      NSSound.beep()
    }
  }

  func commitCompletion(insert: String = "") {
    bridge.core.insertText(
      text: completionContext.selectedText + insert,
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

private extension EditorViewController {
  func updateCompletionPanel(isVisible: Bool) {
    let changed = completionContext.isPanelVisible != isVisible
    if isVisible {
      completionContext.appearance = view.effectiveAppearance
    }

    if completionContext.isPanelVisible != isVisible {
      completionContext.isPanelVisible = isVisible
    }

    if changed {
      bridge.completion.setState(panelVisible: isVisible)

      if isVisible {
        NSSpellChecker.shared.declineCorrectionIndicator(for: webView)
      }
    }
  }

  func updateCompletionPanel(completions: [String], query: String) {
    guard completionContext.isPanelVisible else {
      return
    }

    Task {
      // Get the rectangle at the beginning of the word.
      //
      // For example, for "Hello", we are showing the panel at position relative to letter "H".
      if let caretRect = try? await bridge.selection.getRect(pos: completionContext.fromIndex) {
        updateCompletionPanel(
          completions: completions,
          query: query,
          caretRect: caretRect.cgRect
        )
      }
    }
  }

  func updateCompletionPanel(completions: [String], query: String, caretRect: CGRect) {
    guard completionContext.isPanelVisible, let parentWindow = view.window else {
      return
    }

    completionContext.updateCompletions(
      completions,
      query: query,
      parentWindow: parentWindow,
      caretRect: caretRect.offsetBy(dx: 0, dy: contentRectOffset)
    )
  }
}
