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
    let mode = isRevisionMode ? .hidden : mode
    findPanel.searchField.isHidden = isRevisionMode

    if mode != .hidden {
      // Move the focus to find panel, which causes the WebView to lose focus immediately
      view.window?.makeFirstResponder(findPanel)

      // Move the focus to text field, with a delay to make the focus ring animation more natural
      DispatchQueue.afterDelay(seconds: 0.1) {
        let textField = mode == .replace ? self.replacePanel.textField : self.findPanel.searchField
        textField.startEditing(in: self.view.window)
        textField.selectAll()
      }
    }

    if let searchTerm {
      findPanel.searchField.stringValue = searchTerm
      if searchTerm.isEmpty {
        findPanel.updateResult(numberOfItems: 0, emptyInput: true)
      }
    }

    // If the target mode is find and the current mode is not hidden, we will also skip
    guard findPanel.mode != mode, mode != .find || findPanel.mode == .hidden else {
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

    // Unhide panels by checking the mode, see below for details about this UI trick
    if mode != .hidden {
      findPanel.isHidden = false
    }

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

      // Must leverage isHidden to control the visibility,
      // because alpha = 0 still tracks mouse and visible to VoiceOver.
      if mode == .hidden {
        self.findPanel.isHidden = true
      }

      if mode != .replace {
        self.replacePanel.isHidden = true
      }
    }
  }

  func updateTextFinderModeIfNeeded(_ event: NSEvent) {
    guard findPanel.isFirstResponder || replacePanel.isFirstResponder else {
      return
    }

    // Handle keyboard events when focus is not in the editor
    switch event.deviceIndependentFlags {
    case .command:
      updateTextFinderMode(.find)
    case [.option, .command]:
      updateTextFinderMode(.replace)
    default:
      break
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
