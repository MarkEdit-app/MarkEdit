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
    var completions = spellChecker.completions(
      forPartialWordRange: partialRange,
      in: anchor.text,
      language: nil,
      inSpellDocumentWithTag: 0
    ) ?? []

    // Remove tokens if they "cannot be completed", usually means they are not a word
    let isWord = completions.contains { $0.lowercased() == prefix }
    completions.append(contentsOf: tokenizedWords.filter { isWord || $0.lowercased() != prefix })

    let isPanelVisible = !prefix.isEmpty && !{
      // isMisspelled is the last thing here to leverage short-circuit evaluation
      return !isWord && spellChecker.isMisspelled(word: prefix)
    }()

    updateCompletionPanel(isVisible: isPanelVisible)
  }

  func commitCompletion() {
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

    // We prefer completion over correction,
    // as long as completion panel shows, we should hide the spellcheck panel.
    if changed {
      bridge.completion.setState(panelVisible: isVisible)
      updateSpellCheckPanel(isVisible: !isVisible)
    }
  }

  func updateSpellCheckPanel(isVisible: Bool) {
    if isVisible {
      NSSpellChecker.showPanels()
    } else {
      NSSpellChecker.hidePanels()
      bridge.textChecker.dismiss()
    }
  }
}
