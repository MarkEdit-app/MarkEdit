//
//  EditorFindPanel+Menu.swift
//  MarkEditMac
//
//  Created by cyan on 12/25/22.
//

import AppKit

extension EditorFindPanel {
  /// Reset the search menu, generally after search mode changed.
  func resetMenu() {
    let menu = NSMenu()
    menu.addItem(withTitle: Localized.Search.find, action: #selector(enableFindMode(_:))).setOn(mode != .replace)
    menu.addItem(withTitle: Localized.Search.replace, action: #selector(enableReplaceMode(_:))).setOn(mode == .replace)
    menu.addItem(.separator())

    let caseItem = menu.addItem(withTitle: Localized.Search.caseSensitive, action: #selector(toggleCaseSensitive(_:)))
    caseItem.setOn(AppPreferences.Search.caseSensitive)

    let wholeWordItem = menu.addItem(withTitle: Localized.Search.wholeWord, action: #selector(toggleWholeWord(_:)))
    wholeWordItem.setOn(AppPreferences.Search.wholeWord)

    let literalItem = menu.addItem(withTitle: Localized.Search.literalSearch, action: #selector(toggleLiteralSearch(_:)))
    literalItem.setOn(AppPreferences.Search.literalSearch)
    menu.addItem(.separator())

    let regexItem = menu.addItem(withTitle: Localized.Search.regularExpression, action: #selector(toggleRegularExpression(_:)))
    regexItem.setOn(AppPreferences.Search.regularExpression)
    menu.addItem(.separator())

    let recentsTitleItem = menu.addItem(withTitle: Localized.Search.recentSearches)
    recentsTitleItem.tag = NSSearchField.recentsTitleMenuItemTag

    // Just a placeholder with defined tag to help AppKit find the location
    let recentsPlaceholderItem = menu.addItem(withTitle: "")
    recentsPlaceholderItem.tag = NSSearchField.recentsMenuItemTag
    menu.addItem(.separator())

    let clearRecentsItem = menu.addItem(withTitle: Localized.Search.clearRecents)
    clearRecentsItem.tag = NSSearchField.clearRecentsMenuItemTag

    searchField.recentsAutosaveName = "search.recents-autosaved"
    searchField.maximumRecents = 5
    searchField.searchMenuTemplate = menu
  }
}

// MARK: - Private

private extension EditorFindPanel {
  @objc func enableFindMode(_ sender: NSMenuItem) {
    delegate?.editorFindPanel(self, modeDidChange: .find)
  }

  @objc func enableReplaceMode(_ sender: NSMenuItem) {
    delegate?.editorFindPanel(self, modeDidChange: .replace)
  }

  @objc func toggleCaseSensitive(_ sender: NSMenuItem) {
    AppPreferences.Search.caseSensitive.toggle()
    toggleMenuItem(sender)
  }

  @objc func toggleWholeWord(_ sender: NSMenuItem) {
    AppPreferences.Search.wholeWord.toggle()
    toggleMenuItem(sender)
  }

  @objc func toggleLiteralSearch(_ sender: NSMenuItem) {
    AppPreferences.Search.literalSearch.toggle()
    toggleMenuItem(sender)
  }

  @objc func toggleRegularExpression(_ sender: NSMenuItem) {
    AppPreferences.Search.regularExpression.toggle()
    toggleMenuItem(sender)
  }

  func toggleMenuItem(_ item: NSMenuItem) {
    item.toggle()
    delegate?.editorFindPanelDidChangeOptions(self)
  }
}
