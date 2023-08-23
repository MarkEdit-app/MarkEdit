//
//  EditorViewController+TextFinder.swift
//  MarkEditMac
//
//  Created by cyan on 12/18/22.
//

import AppKit
import MarkEditKit

extension EditorViewController {
  func updateTextFinderMode(_ mode: EditorFindMode, searchTerm: String? = nil) {
    // In viewing mode, always set the mode to hidden and hide the search field,
    // this is to break a mystery retain cycle caused by NSDocument version browsing.
    let mode = isReadOnly ? .hidden : mode
    findPanel.searchField.isHidden = isReadOnly

    if mode != .hidden {
      // Move the focus to find panel, with a delay to make the focus ring animation more natural
      DispatchQueue.afterDelay(seconds: 0.1) {
        self.findPanel.searchField.startEditing(in: self.view.window)
      }
    }

    if let searchTerm {
      findPanel.searchField.stringValue = searchTerm
      if searchTerm.isEmpty {
        findPanel.updateResult(numberOfItems: 0, emptyInput: true)
      }
    }

    guard findPanel.mode != mode else {
      return
    }

    hasUnfinishedAnimations = true
    findPanel.mode = mode
    findPanel.resetMenu()

    // Move the focus back to editor
    if mode == .hidden {
      startWebViewEditing()
      bridge.search.setState(enabled: false)
    }

    // Unhide the replace panel, see below for details about this UI trick
    if mode == .replace {
      replacePanel.isHidden = false
    }

    // Animate layout changes
    NSAnimationContext.runAnimationGroup(
      duration: 0.2
    ) { _ in
      findPanel.animator().alphaValue = mode == .hidden ? 0 : 1
      replacePanel.animator().alphaValue = mode == .replace ? 1 : 0
      layoutPanels(animated: true)
      layoutWebView(animated: true)
    } completionHandler: {
      self.hasUnfinishedAnimations = false

      // Must set isHidden because it is behind the find panel,
      // alpha = 0 still tracks mouse, which makes the cursor "i-beam" for the magnifier
      if mode != .replace {
        self.replacePanel.isHidden = true
      }
    }
  }

  func updateTextFinderQuery(refocus: Bool = true) {
    let options = SearchOptions(
      search: searchTerm,
      caseSensitive: AppPreferences.Search.caseSensitive,
      literal: AppPreferences.Search.literalSearch,
      regexp: AppPreferences.Search.regularExpression,
      wholeWord: AppPreferences.Search.wholeWord,
      refocus: refocus,
      replace: replacePanel.textField.stringValue
    )

    findPanel.searchField.addToRecents(searchTerm: searchTerm)
    findPanel.resetMenu()

    Task {
      if let count = try? await bridge.search.updateQuery(options: options) {
        updateTextFinderPanels(numberOfItems: count)
      }
    }
  }

  func updateTextFinderPanels(numberOfItems: Int) {
    findPanel.updateResult(numberOfItems: numberOfItems, emptyInput: searchTerm.isEmpty)
    replacePanel.updateResult(numberOfItems: numberOfItems)
  }

  func findSelectionInTextFinder() {
    updateTextFinderMode(.find)

    Task {
      guard let text = try? await bridge.selection.getText() else {
        return
      }

      findPanel.searchField.stringValue = text
      DispatchQueue.afterDelay(seconds: 0.2) { // 0.2 is the animation duration of panel
        self.updateTextFinderQuery(refocus: false)
      }
    }
  }

  func findNextInTextFinder() {
    prepareFinderNavigation()
    bridge.search.findNext(search: searchTerm)
  }

  func findPreviousInTextFinder() {
    prepareFinderNavigation()
    bridge.search.findPrevious(search: searchTerm)
  }

  func replaceNextInTextFinder() {
    bridge.search.replaceNext()
  }

  func replaceAllInTextFinder() {
    bridge.search.replaceAll()
  }

  func selectAllOccurrences() {
    bridge.search.selectAllOccurrences()
  }
}

// MARK: - Private

private extension EditorViewController {
  var searchTerm: String {
    findPanel.searchField.stringValue
  }

  func prepareFinderNavigation() {
    if findPanel.numberOfItems == 1 {
      NSSound.beep()
    }

    if findPanel.mode == .hidden {
      updateTextFinderMode(.find)
    }
  }
}
