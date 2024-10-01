//
//  EditorFindPanel+Menu.swift
//  MarkEditMac
//
//  Created by cyan on 12/25/22.
//

import AppKit
import MarkEditKit

extension EditorFindPanel {
  /// Reset the search menu, generally after search mode changed.
  func resetMenu() {
    let menu = NSMenu()
    menu.addItem(withTitle: Localized.Search.find, action: #selector(enableFindMode(_:))).setOn(mode != .replace)
    menu.addItem(withTitle: Localized.Search.replace, action: #selector(enableReplaceMode(_:))).setOn(mode == .replace)
    menu.addItem(.separator())

    let caseItem = menu.addItem(withTitle: Localized.Search.caseSensitive, action: #selector(toggleCaseSensitive(_:)))
    caseItem.tag = Option.caseSensitive.rawValue
    caseItem.setOn(AppPreferences.Search.caseSensitive)

    let wholeWordItem = menu.addItem(withTitle: Localized.Search.wholeWord, action: #selector(toggleWholeWord(_:)))
    wholeWordItem.tag = Option.wholeWord.rawValue
    wholeWordItem.setOn(AppPreferences.Search.wholeWord)

    let literalItem = menu.addItem(withTitle: Localized.Search.literalSearch, action: #selector(toggleLiteralSearch(_:)))
    literalItem.tag = Option.literalSearch.rawValue
    literalItem.setOn(AppPreferences.Search.literalSearch)

    let regexItem = menu.addItem(withTitle: Localized.Search.regularExpression, action: #selector(toggleRegularExpression(_:)))
    regexItem.tag = Option.regularExpression.rawValue
    regexItem.setOn(AppPreferences.Search.regularExpression)
    menu.addItem(.separator())

    if let operationsItem = delegate?.editorFindPanelOperationsMenuItem(self) {
      menu.addItem(operationsItem)
      menu.addItem(.separator())
    }

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
    updateIconTintColor()
  }
}

// MARK: - Private

private extension EditorFindPanel {
  enum Option: Int, CaseIterable {
    case caseSensitive = 20001
    case wholeWord = 20002
    case literalSearch = 20003
    case regularExpression = 20004
  }

  @objc func enableFindMode(_ sender: NSMenuItem) {
    delegate?.editorFindPanel(self, modeDidChange: .find)
  }

  @objc func enableReplaceMode(_ sender: NSMenuItem) {
    delegate?.editorFindPanel(self, modeDidChange: .replace)
  }

  @objc func toggleCaseSensitive(_ sender: NSMenuItem) {
    AppPreferences.Search.caseSensitive.toggle()
    updateOptions(sender)
  }

  @objc func toggleWholeWord(_ sender: NSMenuItem) {
    AppPreferences.Search.wholeWord.toggle()
    updateOptions(sender)
  }

  @objc func toggleLiteralSearch(_ sender: NSMenuItem) {
    AppPreferences.Search.literalSearch.toggle()
    updateOptions(sender)
  }

  @objc func toggleRegularExpression(_ sender: NSMenuItem) {
    AppPreferences.Search.regularExpression.toggle()
    updateOptions(sender)
  }

  func updateOptions(_ item: NSMenuItem) {
    item.toggle()
    updateIconTintColor()
    delegate?.editorFindPanelDidChangeOptions(self)
  }

  func updateIconTintColor() {
    let shouldTint = (searchField.searchMenuTemplate?.items.filter {
      Option.allCases.map { $0.rawValue }.contains($0.tag)
    })?.contains { $0.state == .on } ?? false

    let tintColor: NSColor? = shouldTint ? .controlAccentColor : nil
    searchField.setIconTintColor(tintColor)
  }
}
