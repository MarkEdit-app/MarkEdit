//
//  EditorViewController+TextFinder.swift
//  MarkEditMac
//
//  Created by cyan on 12/18/22.
//

import AppKit
import MarkEditKit

extension EditorViewController {
  func updateTextFinderMode(
    _ mode: EditorFindMode,
    searchTerm: String? = nil,
    explicitly: Bool = false
  ) {
    guard !hasUnfinishedAnimations else {
      return
    }

    // In viewing mode, always set the mode to hidden and hide the search field,
    // this is to break a mystery retain cycle caused by NSDocument version browsing.
    let mode = isRevisionMode ? .hidden : mode
    findPanel.searchField.isHidden = isRevisionMode

    if mode != .hidden {
      // When the user explicitly changes the mode to replace (from the find panel menu),
      // the focus should still be the find field.
      let textField = (mode == .replace && !explicitly) ? replacePanel.textField : findPanel.searchField
      textField.selectAll()

      if !textField.isFirstResponder(in: view.window) {
        textField.focusRingType = .none
        textField.startEditing(in: view.window)

        // Delay showing the focus ring to make the animation more natural
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
          textField.focusRingType = .default
          textField.startEditing(in: self.view.window, alwaysRefocus: true)
        }
      }
    }

    if let searchTerm {
      findPanel.searchField.stringValue = searchTerm
      if searchTerm.isEmpty {
        findPanel.updateResult(numberOfItems: 0, emptyInput: true)
      }
    }

    let needsUpdate = {
      // From the find panel menu, the user explicitly wants to change the mode
      if explicitly {
        return findPanel.mode != mode
      }

      // If the target mode is find and the current mode is not hidden, we will also skip
      return findPanel.mode != mode && (mode != .find || findPanel.mode == .hidden)
    }()

    guard needsUpdate else {
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

  /**
   Move the focus between two text fields in search panel.

   Returns true to stop event propagation.
   */
  func updateTextFinderModeIfNeeded(_ event: NSEvent) -> Bool {
    guard findPanel.isFirstResponder || replacePanel.isFirstResponder else {
      return false
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

    return true
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
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { // 0.2 is the animation duration of panel
        self.updateTextFinderQuery()
      }
    }
  }

  func findNextInTextFinder() {
    prepareFinderNavigation()

    Task {
      let hadSelectedMatch = (try? await bridge.search.findNext(search: searchTerm)) ?? false
      finishFinderNavigation(hadSelectedMatch: hadSelectedMatch)
    }
  }

  func findPreviousInTextFinder() {
    prepareFinderNavigation()

    Task {
      let hadSelectedMatch = (try? await bridge.search.findPrevious(search: searchTerm)) ?? false
      finishFinderNavigation(hadSelectedMatch: hadSelectedMatch)
    }
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

  func performSearchOperation(_ operation: SearchOperation) {
    bridge.search.performOperation(operation: operation)

    if operation == .selectAll || operation == .selectAllInSelection {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { self.startWebViewEditing() }
    }
  }
}

// MARK: - Private

private extension EditorViewController {
  var searchTerm: String {
    findPanel.searchField.stringValue
  }

  func prepareFinderNavigation() {
    guard findPanel.mode == .hidden else {
      return
    }

    updateTextFinderMode(.find)
  }

  func finishFinderNavigation(hadSelectedMatch: Bool) {
    guard (hadSelectedMatch && findPanel.numberOfItems == 1) || findPanel.numberOfItems == 0 else {
      return
    }

    NSSound.beep()
  }
}
