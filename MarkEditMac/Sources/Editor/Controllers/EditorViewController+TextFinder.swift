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
    explicitly: Bool = false,
    startsEditing: Bool = true
  ) {
    guard !hasUnfinishedAnimations else {
      return
    }

    if mode != .hidden {
      configureFieldEditor()
      removeFloatingUIElements()

      // Open the find panel with a query update from other apps
      if findPanel.mode == .hidden && nativeSearchQueryChanged {
        updateTextFinderQuery()
      }

      // When the user explicitly changes the mode to replace (from the find panel menu),
      // the focus should still be the find field.
      let textField = (mode == .replace && !explicitly) ? replacePanel.textField : findPanel.searchField
      textField.selectAll()

      if startsEditing && !textField.isFirstResponder(in: view.window) {
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
        findPanel.updateResult(counter: .init(numberOfItems: 0, currentIndex: -1), emptyInput: true)
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
      startTextEditing()
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
    NSAnimationContext.runAnimationGroup { context in
      context.duration = 0.2
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
    guard isFindPanelFirstResponder else {
      return false
    }

    // Handle keyboard events when focus is not in the editor
    switch event.deviceIndependentFlags {
    case .command:
      updateTextFinderMode(.find)
      return true
    case [.option, .command]:
      updateTextFinderMode(.replace)
      return true
    default:
      return false
    }
  }

  func updateTextFinderQuery(refocus: Bool = true) {
    let options = SearchOptions(
      search: searchTerm,
      caseSensitive: AppPreferences.Search.caseSensitive,
      diacriticInsensitive: AppPreferences.Search.diacriticInsensitive,
      wholeWord: AppPreferences.Search.wholeWord,
      literal: AppPreferences.Search.literalSearch,
      regexp: AppPreferences.Search.regularExpression,
      refocus: refocus,
      replace: replacePanel.textField.stringValue
    )

    findPanel.searchField.addToRecents(searchTerm: searchTerm)
    findPanel.resetMenu()

    bridge.search.updateQuery(options: options)
    updateSearchCounter()

    if AppRuntimeConfig.nativeSearchQuerySync {
      nativeSearchQueryChanged = false
      NSPasteboard.find.string = searchTerm
    }
  }

  func updateNativeSearchQuery() {
    guard let query = NSPasteboard.find.string, query != findPanel.searchField.stringValue else {
      return
    }

    findPanel.searchField.stringValue = query
    findPanel.searchField.selectAll()
    nativeSearchQueryChanged = true

    if findPanel.isFirstResponder {
      updateTextFinderQuery()
    } else {
      findPanel.clearCounter()
    }
  }

  func updateSearchCounter() {
    Task {
      if let counter = try? await bridge.search.getCounterInfo() {
        updateTextFinderPanels(counter: counter)
      }
    }
  }

  func findSelectionInTextFinder() {
    let reselectTerm = webView.isFirstResponder
    updateTextFinderMode(.find, startsEditing: false)

    Task {
      guard let text = try? await bridge.selection.getText() else {
        return
      }

      if text.isEmpty && !reselectTerm {
        NSSound.beep()
      }

      findPanel.searchField.stringValue = text
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { // 0.2 is the animation duration of panel
        self.updateTextFinderQuery()
      }
    }
  }

  func findNextInTextFinder() {
    Task {
      await navigateFindResults(backwards: false)
    }
  }

  func findPreviousInTextFinder() {
    Task {
      await navigateFindResults(backwards: true)
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

  func selectNextOccurrence() {
    Task {
      if let foundNext = try? await bridge.search.selectNextOccurrence(), !foundNext {
        NSSound.beep()
      }
    }
  }

  func performSearchOperation(_ operation: SearchOperation) {
    bridge.search.performOperation(operation: operation)

    if operation == .selectAll || operation == .selectAllInSelection {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { self.startTextEditing() }
    }
  }
}

// MARK: - Private

private extension EditorViewController {
  enum States {
    @MainActor static var configuredFieldEditor = false
  }

  var fieldEditor: NSText? {
    view.window?.fieldEditor(true, for: nil)
  }

  var searchTerm: String {
    findPanel.searchField.stringValue
  }

  func configureFieldEditor() {
    guard !States.configuredFieldEditor else {
      return
    }

    let menu = fieldEditor?.menu
    menu?.addItem(.separator())

    menu?.addItem(withTitle: Localized.General.insertTab) { [weak self] in
      self?.fieldEditor?.insertText("\t")
    }

    menu?.addItem(withTitle: Localized.General.insertLineBreak) { [weak self] in
      self?.fieldEditor?.insertText("\n")
    }

    menu?.addItem(.separator())
    States.configuredFieldEditor = true
  }

  func updateTextFinderPanels(counter: SearchCounterInfo) {
    findPanel.updateResult(counter: counter, emptyInput: searchTerm.isEmpty)
    replacePanel.updateResult(numberOfItems: counter.numberOfItems)
  }

  func navigateFindResults(backwards: Bool) async {
    guard !nativeSearchQueryChanged else {
      return updateTextFinderQuery()
    }

    let wasPanelHidden = findPanel.mode == .hidden
    let reselectTerm = webView.isFirstResponder && (wasPanelHidden || searchTerm.isEmpty)

    if reselectTerm, let text = try? await bridge.selection.getText() {
      findPanel.searchField.stringValue = text
      updateTextFinderQuery()
    }

    if wasPanelHidden {
      updateTextFinderMode(.find, startsEditing: false)
    }

    let navigate = backwards ? bridge.search.findPrevious : bridge.search.findNext
    let hadSelectedMatch = (try? await navigate(searchTerm)) ?? false

    if !reselectTerm {
      finishFinderNavigation(hadSelectedMatch: hadSelectedMatch)
    }

    updateSearchCounter()
  }

  func finishFinderNavigation(hadSelectedMatch: Bool) {
    guard (hadSelectedMatch && findPanel.numberOfItems == 1) || findPanel.numberOfItems == 0 else {
      return
    }

    NSSound.beep()
  }
}
