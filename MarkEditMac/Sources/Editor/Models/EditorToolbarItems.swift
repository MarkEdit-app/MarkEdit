//
//  EditorToolbarItems.swift
//  MarkEditMac
//
//  Created by cyan on 1/13/23.
//

import AppKit
import MarkEditKit

extension NSToolbarItem {
  static func with(identifier: NSToolbarItem.Identifier, menu: NSMenu?) -> NSMenuToolbarItem {
    let item = NSMenuToolbarItem(itemIdentifier: identifier)
    item.label = identifier.itemLabel
    item.image = NSImage(systemSymbolName: identifier.itemIcon, accessibilityDescription: item.label)

    if let menu {
      item.menu = menu
    } else {
      Logger.log(.error, "Missing menu for NSMenuToolbarItem")
    }

    return item
  }

  static func with(identifier: NSToolbarItem.Identifier, iconSize: Double? = nil, action: @escaping () -> Void) -> NSToolbarItem {
    let item = NSToolbarItem(itemIdentifier: identifier)
    item.label = identifier.itemLabel

    if let iconSize {
      item.image = .with(
        symbolName: identifier.itemIcon,
        pointSize: iconSize,
        accessibilityLabel: item.label
      )
    } else {
      item.image = NSImage(systemSymbolName: identifier.itemIcon, accessibilityDescription: item.label)
    }

    item.addAction(action)
    return item
  }

  /// Used in toolTip as a hint, values should match mainMenu.
  var shortcutHint: String? {
    switch itemIdentifier {
    case .tableOfContents: return "⇧ ⌘ O"
    case .toggleBold: return "⌘ B"
    case .toggleItalic: return "⌘ I"
    case .toggleStrikethrough: return "⌃ ⌘ S"
    case .insertLink: return "⌘ K"
    case .insertImage: return "⌃ ⌘ K"
    case .statistics: return "⇧ ⌘ I"
    default: return nil
    }
  }
}

extension NSToolbarItem.Identifier {
  static let tableOfContents = newItem("tableOfContents")
  static let formatHeaders = newItem("formatHeaders")
  static let toggleBold = newItem("toggleBold")
  static let toggleItalic = newItem("toggleItalic")
  static let toggleStrikethrough = newItem("toggleStrikethrough")
  static let insertLink = newItem("insertLink")
  static let insertImage = newItem("insertImage")
  static let toggleList = newItem("toggleList")
  static let toggleBlockquote = newItem("toggleBlockquote")
  static let horizontalRule = newItem("horizontalRule")
  static let insertTable = newItem("insertTable")
  static let insertCode = newItem("insertCode")
  static let textFormat = newItem("textFormat")
  static let statistics = newItem("statistics")
  static let shareDocument = newItem("shareDocument")
  static let copyPandocCommand = newItem("copyPandocCommand")

  static var defaultItems: [NSToolbarItem.Identifier] {
    [
      .tableOfContents,
      .formatHeaders,
      .toggleBold,
      .toggleItalic,
      .toggleList,
    ]
  }

  static var allItems: [NSToolbarItem.Identifier] {
    [
      .tableOfContents,
      .formatHeaders,
      .toggleBold,
      .toggleItalic,
      .toggleStrikethrough,
      .insertLink,
      .insertImage,
      .toggleList,
      .toggleBlockquote,
      .horizontalRule,
      .insertTable,
      .insertCode,
      .textFormat,
      .statistics,
      .shareDocument,
      .copyPandocCommand,
      .space,
      .flexibleSpace,
    ]
  }
}

// MARK: - Private

private extension NSToolbarItem.Identifier {
  static func newItem(_ identifier: String) -> Self {
    Self("app.markedit.editor.\(identifier)")
  }

  var itemLabel: String {
    switch self {
    case .tableOfContents: return Localized.Toolbar.tableOfContents
    case .formatHeaders: return Localized.Toolbar.formatHeaders
    case .toggleBold: return Localized.Toolbar.toggleBold
    case .toggleItalic: return Localized.Toolbar.toggleItalic
    case .toggleStrikethrough: return Localized.Toolbar.toggleStrikethrough
    case .insertLink: return Localized.Toolbar.insertLink
    case .insertImage: return Localized.Toolbar.insertImage
    case .toggleList: return Localized.Toolbar.toggleList
    case .toggleBlockquote: return Localized.Toolbar.toggleBlockquote
    case .horizontalRule: return Localized.Toolbar.horizontalRule
    case .insertTable: return Localized.Toolbar.insertTable
    case .insertCode: return Localized.Toolbar.insertCode
    case .textFormat: return Localized.Toolbar.textFormat
    case .statistics: return Localized.Toolbar.statistics
    case .shareDocument: return Localized.Toolbar.shareDocument
    case .copyPandocCommand: return Localized.Toolbar.copyPandocCommand
    default: fatalError("Unexpected toolbar item identifier: \(self)")
    }
  }

  var itemIcon: String {
    switch self {
    case .tableOfContents: return Icons.listBulletRectangle
    case .formatHeaders: return Icons.number
    case .toggleBold: return Icons.bold
    case .toggleItalic: return Icons.italic
    case .toggleStrikethrough: return Icons.strikethrough
    case .insertLink: return Icons.link
    case .insertImage: return Icons.photo
    case .toggleList: return Icons.listBullet
    case .toggleBlockquote: return Icons.textQuote
    case .horizontalRule: return Icons.squareSplit1x2
    case .insertTable: return Icons.tablecells
    case .insertCode: return Icons.curlybracesSquare
    case .textFormat: return Icons.textformat
    case .statistics: return Icons.exclamationmarkCircle
    case .shareDocument: return Icons.squareAndArrowUp
    case .copyPandocCommand: return Icons.terminal
    default: fatalError("Unexpected toolbar item identifier: \(self)")
    }
  }
}
