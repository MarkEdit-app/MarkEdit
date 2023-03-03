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
      return updateCompletionPanel(isVisible: false)
    }

    var completions = spellChecker.completions(
      forPartialWordRange: partialRange,
      in: anchor.text,
      language: nil,
      inSpellDocumentWithTag: 0
    ) ?? []

    // Remove tokens if they "cannot be completed", usually means they are not a word
    let isWord = completions.contains { $0.lowercased() == prefix }
    completions.append(contentsOf: tokenizedWords.filter { isWord || $0.lowercased() != prefix })

    updateCompletionPanel(isVisible: !completions.isEmpty)
    updateCompletionPanel(completions: completions, position: anchor.offset + partialRange.location)
  }

  func commitCompletion() {
    updateCompletionPanel(isVisible: false)
  }

  func cancelCompletion() {
    updateCompletionPanel(isVisible: false)
  }

  func selectPreviousCompletion() {
    // tbd
  }

  func selectNextCompletion() {
    // tbd
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

  private func updateCompletionPanel(completions: [String], position: Int) {
    guard completionContext.isPanelVisible else {
      return
    }

    Task {
      if let caretRect = try? await bridge.selection.getRect(pos: position) {
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
