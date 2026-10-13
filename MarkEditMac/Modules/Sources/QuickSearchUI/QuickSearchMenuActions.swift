//
//  QuickSearchMenuActions.swift
//
//  Created by cyan on 10/12/26.
//

import AppKit
import QuickSearchCore

@MainActor
final class QuickSearchMenuActions {
  private let menu: NSMenu
  private let openRecentMenu: NSMenu?
  private weak var sourceWindow: NSWindow?
  private let hadSourceWindow: Bool
  private let refocusSourceWindow: @MainActor () async throws -> Void
  private(set) var actions: [MenuActionSearchResult.Action] = []

  init(
    menu: NSMenu,
    sourceWindow: NSWindow?,
    openRecentMenu: NSMenu? = nil,
    refocusSourceWindow: (@MainActor () async throws -> Void)? = nil
  ) {
    self.menu = menu
    self.openRecentMenu = openRecentMenu
    self.sourceWindow = sourceWindow
    hadSourceWindow = sourceWindow != nil
    self.refocusSourceWindow = refocusSourceWindow ?? { [weak sourceWindow] in
      sourceWindow?.makeKeyAndOrderFront(nil)
    }

    collect(menu)
  }

  func resolve(_ action: MenuActionSearchResult.Action) async throws -> NSMenuItem? {
    if hadSourceWindow {
      guard let sourceWindow, sourceWindow.isVisible else {
        return nil
      }

      try await refocusSourceWindow()
    }

    try Task.checkCancellation()
    guard NSApp.keyWindow === sourceWindow, !hadSourceWindow || sourceWindow?.isVisible == true else {
      return nil
    }

    // Trust the live enabled state; refreshing menus here can temporarily re-enable disabled items
    var menu = menu
    for (depth, index) in action.indices.enumerated() {
      guard menu.items.indices.contains(index) else {
        return nil
      }

      let item = menu.items[index]

      guard isSearchable(item), item.isEnabled, item.title == action.titles[depth] else {
        return nil
      }

      if depth == action.indices.count - 1 {
        return item.submenu == nil && hasTarget(item) ? item : nil
      }

      guard let submenu = item.submenu else {
        return nil
      }

      menu = submenu
    }

    return nil
  }

  private func collect(_ menu: NSMenu, indices: [Int] = [], titles: [String] = []) {
    menu.delegate?.menuNeedsUpdate?(menu)
    menu.update()

    for (index, item) in menu.items.enumerated() where isSearchable(item) {
      let indices = indices + [index]
      let titles = titles + [item.title]

      if let submenu = item.submenu {
        collect(submenu, indices: indices, titles: titles)
      } else if item.action != nil {
        actions.append(.init(indices: indices, titles: titles))
      }
    }
  }

  private func isSearchable(_ item: NSMenuItem) -> Bool {
    if item.menu === openRecentMenu, item.action != #selector(NSDocumentController.clearRecentDocuments(_:)) {
      return false
    }

    if item.menu === NSApp.windowsMenu, item.target is NSWindow,
       item.action == #selector(NSWindow.makeKeyAndOrderFront(_:)) {
      return false
    }

    return !item.isSeparatorItem && !item.isHidden && !item.isAlternate && !item.title.isEmpty
  }

  private func hasTarget(_ item: NSMenuItem) -> Bool {
    guard let action = item.action else {
      return false
    }

    return NSApp.target(forAction: action, to: item.target, from: item) != nil
  }
}
