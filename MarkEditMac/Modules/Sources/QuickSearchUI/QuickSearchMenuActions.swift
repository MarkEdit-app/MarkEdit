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
  private let suggestedActions: [Selector]
  private weak var sourceWindow: NSWindow?
  private let hadSourceWindow: Bool
  private let refocusSourceWindow: @MainActor () async throws -> Void
  private(set) var actions: [MenuActionSearchResult.Action] = []

  init(
    menu: NSMenu,
    sourceWindow: NSWindow?,
    openRecentMenu: NSMenu? = nil,
    suggestedActions: [Selector] = [],
    refocusSourceWindow: (@MainActor () async throws -> Void)? = nil
  ) {
    self.menu = menu
    self.openRecentMenu = openRecentMenu
    self.suggestedActions = suggestedActions
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

  private func collect(_ menu: NSMenu, indices: [Int] = [], titles: [String] = [], ancestorsEnabled: Bool = true) {
    menu.delegate?.menuNeedsUpdate?(menu)
    menu.update()

    for (index, item) in menu.items.enumerated() where isSearchable(item) {
      let indices = indices + [index]
      let titles = titles + [item.title]
      let enabled = ancestorsEnabled && item.isEnabled

      if let submenu = item.submenu {
        collect(submenu, indices: indices, titles: titles, ancestorsEnabled: enabled)
      } else if let action = item.action {
        let suggestedOrder = suggestedActions.firstIndex(of: action)
        actions.append(.init(
          indices: indices,
          titles: titles,
          shortcutHint: item.shortcutHint,
          suggestedOrder: suggestedOrder != nil && enabled && hasTarget(item) ? suggestedOrder : nil
        ))
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

private extension NSMenuItem {
  var shortcutHint: String? {
    guard !keyEquivalent.isEmpty else {
      return nil
    }

    var modifiers = keyEquivalentModifierMask
    if keyEquivalent != keyEquivalent.lowercased() {
      modifiers.insert(.shift)
    }

    let key: String
    switch keyEquivalent {
    case "\u{08}", "\u{7F}": key = "\u{232B}"
    case "\t": key = "\u{21E5}"
    case "\u{19}":
      modifiers.insert(.shift)
      key = "\u{21E5}"
    case "\r": key = "\u{21A9}"
    case "\u{03}", "\n": key = "\u{2324}"
    case "\u{1B}": key = "\u{238B}"
    case " ": key = "\u{2423}"
    case "\u{F700}": key = "\u{2191}"
    case "\u{F701}": key = "\u{2193}"
    case "\u{F702}": key = "\u{2190}"
    case "\u{F703}": key = "\u{2192}"
    case "\u{F728}": key = "\u{2326}"
    case "\u{F729}": key = "\u{2196}"
    case "\u{F72B}": key = "\u{2198}"
    case "\u{F72C}": key = "\u{21DE}"
    case "\u{F72D}": key = "\u{21DF}"
    case "\u{F739}": key = "\u{2327}"
    case "\u{F746}": key = "?"
    default:
      if let scalar = keyEquivalent.unicodeScalars.first, (0xF704...0xF726).contains(scalar.value) {
        key = "F\(scalar.value - 0xF704 + 1)"
      } else {
        key = keyEquivalent.uppercased()
      }
    }

    let symbols: [(NSEvent.ModifierFlags, String)] = [
      (.control, "\u{2303}"), (.option, "\u{2325}"), (.shift, "\u{21E7}"), (.command, "\u{2318}"),
    ]

    return symbols.filter { modifiers.contains($0.0) }.map(\.1).joined() + key
  }
}
