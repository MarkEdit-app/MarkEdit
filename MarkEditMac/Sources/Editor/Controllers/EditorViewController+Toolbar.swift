//
//  EditorViewController+Toolbar.swift
//  MarkEditMac
//
//  Created by cyan on 1/13/23.
//

import AppKit
import MarkEditKit

extension EditorViewController {
  var tableOfContentsMenuButton: NSPopUpButton? {
    view.window?.popUpButton(with: Constants.tableOfContentsMenuIdentifier)
  }

  var statisticsSourceView: NSView? {
    // Present the popover relative to the toolbar item
    view.window?.toolbarButton(with: statisticsItem.itemIdentifier) ??
    // Present the popover relative to the document title view
    view.window?.toolbarTitleView
  }

  private enum Constants {
    static let tableOfContentsMenuIdentifier = NSUserInterfaceItemIdentifier("tableOfContentsMenu")
    static let tableOfContentsMinimumWidth: Double = 160
    static let normalizedButtonSize: Double = 15 // "bold" icon looks bigger than expected, fix it
  }

  func updateToolbarItemMenus(_ menu: NSMenu) {
    if menu.identifier == Constants.tableOfContentsMenuIdentifier {
      updateTableOfContentsMenu(menu)
    }
  }

  func showTableOfContentsMenu() {
    bridge.core.handleFocusLost()
    presentedPopover?.close()

    // Pop up the menu relative to the toolbar item
    if let tableOfContentsMenuButton {
      return RunLoop.main.perform(inModes: [.default, .eventTracking]) {
        MainActor.assumeIsolated {
          tableOfContentsMenuButton.performClick(nil)
        }
      }
    }

    // Pop up the menu relative to the document title view
    if let menu = (tableOfContentsItem as? NSMenuToolbarItem)?.menu,
       let sourceView = view.window?.toolbarTitleView {
      menu.popUp(
        positioning: nil,
        at: CGPoint(x: sourceView.bounds.minX, y: sourceView.bounds.maxY + 15),
        in: sourceView
      )
      return
    }
  }
}

// MARK: - NSToolbarDelegate

extension EditorViewController: NSToolbarDelegate {
  func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
    let item: NSToolbarItem? = {
      switch itemIdentifier {
      case .tableOfContents: return tableOfContentsItem
      case .formatHeaders: return formatHeadersItem
      case .toggleBold: return toggleBoldItem
      case .toggleItalic: return toggleItalicItem
      case .toggleStrikethrough: return toggleStrikethroughItem
      case .insertLink: return insertLinkItem
      case .insertImage: return insertImageItem
      case .toggleList: return toggleListItem
      case .toggleBlockquote: return toggleBlockquoteItem
      case .horizontalRule: return horizontalRuleItem
      case .insertTable: return insertTableItem
      case .insertCode: return insertCodeItem
      case .textFormat: return textFormatItem
      case .statistics: return statisticsItem
      case .shareDocument: return shareDocumentItem
      case .copyPandocCommand: return copyPandocCommandItem
      case .writingTools: return writingToolsItem
      default: return nil
      }
    }()

    if let item, item.toolTip == nil {
      if let shortcutHint = item.shortcutHint {
        item.toolTip = "\(item.label) (\(shortcutHint))"
      } else {
        item.toolTip = item.label
      }
    }

    item?.isBordered = true
    return item
  }

  func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    NSToolbarItem.Identifier.defaultItems
  }

  func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    NSToolbarItem.Identifier.allItems
  }
}

// MARK: - NSToolbarItemValidation

extension EditorViewController: NSToolbarItemValidation {
  func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
    true
  }
}

// MARK: - NSSharingServicePickerToolbarItemDelegate

extension EditorViewController: NSSharingServicePickerToolbarItemDelegate {
  func items(for pickerToolbarItem: NSSharingServicePickerToolbarItem) -> [Any] {
    guard let document else {
      return []
    }

    return [document]
  }
}

// MARK: - Private

private extension EditorViewController {
  var tableOfContentsItem: NSToolbarItem {
    let menu = NSMenu()
    menu.delegate = self
    menu.identifier = Constants.tableOfContentsMenuIdentifier
    menu.minimumWidth = Constants.tableOfContentsMinimumWidth

    let label = NSMenuItem(title: Localized.Toolbar.tableOfContents, action: nil, keyEquivalent: "")
    label.isEnabled = false

    menu.items = [label, .separator()]
    menu.autoenablesItems = false

    return .with(identifier: .tableOfContents, menu: menu)
  }

  var formatHeadersItem: NSToolbarItem {
    .with(identifier: .formatHeaders, menu: NSApp.appDelegate?.formatHeadersMenu?.copiedMenu)
  }

  var toggleBoldItem: NSToolbarItem {
    .with(identifier: .toggleBold, iconSize: Constants.normalizedButtonSize) { [weak self] in
      self?.toggleBold(nil)
    }
  }

  var toggleItalicItem: NSToolbarItem {
    .with(identifier: .toggleItalic, iconSize: Constants.normalizedButtonSize) { [weak self] in
      self?.toggleItalic(nil)
    }
  }

  var toggleStrikethroughItem: NSToolbarItem {
    .with(identifier: .toggleStrikethrough, iconSize: Constants.normalizedButtonSize) { [weak self] in
      self?.toggleStrikethrough(nil)
    }
  }

  var insertLinkItem: NSToolbarItem {
    .with(identifier: .insertLink) { [weak self] in
      self?.insertLink(nil)
    }
  }

  var insertImageItem: NSToolbarItem {
    .with(identifier: .insertImage) { [weak self] in
      self?.insertImage(nil)
    }
  }

  var toggleListItem: NSToolbarItem {
    let menu = NSMenu()
    menu.items = [
      NSApp.appDelegate?.formatBulletItem,
      NSApp.appDelegate?.formatNumberingItem,
      NSApp.appDelegate?.formatTodoItem,
    ].compactMap { $0?.copiedItem }

    return .with(identifier: .toggleList, menu: menu)
  }

  var toggleBlockquoteItem: NSToolbarItem {
    .with(identifier: .toggleBlockquote) { [weak self] in
      self?.toggleBlockquote(nil)
    }
  }

  var horizontalRuleItem: NSToolbarItem {
    .with(identifier: .horizontalRule) { [weak self] in
      self?.insertHorizontalRule(nil)
    }
  }

  var insertTableItem: NSToolbarItem {
    .with(identifier: .insertTable) { [weak self] in
      self?.insertTable(nil)
    }
  }

  var insertCodeItem: NSToolbarItem {
    let menu = NSMenu()
    menu.items = [
      NSApp.appDelegate?.formatCodeItem,
      NSApp.appDelegate?.formatCodeBlockItem,
      NSApp.appDelegate?.formatMathItem,
      NSApp.appDelegate?.formatMathBlockItem,
    ].compactMap { $0?.copiedItem }

    return .with(identifier: .insertCode, menu: menu)
  }

  var textFormatItem: NSToolbarItem {
    .with(identifier: .textFormat, menu: NSApp.appDelegate?.textFormatMenu?.copiedMenu)
  }

  var statisticsItem: NSToolbarItem {
    .with(identifier: .statistics) { [weak self] in
      self?.toggleStatisticsPopover(sourceView: self?.statisticsSourceView)
    }
  }

  var shareDocumentItem: NSToolbarItem {
    let item = NSSharingServicePickerToolbarItem(itemIdentifier: .shareDocument)
    item.toolTip = Localized.Toolbar.shareDocument
    item.image = NSImage(systemSymbolName: Icons.squareAndArrowUp, accessibilityDescription: Localized.Toolbar.shareDocument)
    item.delegate = self
    return item
  }

  var copyPandocCommandItem: NSToolbarItem {
    .with(identifier: .copyPandocCommand, menu: NSApp.appDelegate?.copyPandocCommandMenu?.copiedMenu)
  }

  var writingToolsItem: NSToolbarItem? {
    if #available(macOS 15.1, *), MarkEditWritingTools.isAvailable {
      return .with(identifier: .writingTools, menu: customWritingToolsMenu)
    } else {
      return nil
    }
  }

  func updateTableOfContentsMenu(_ menu: NSMenu) {
    // Remove existing items, the first two are placeholders that we want to keep
    for (index, item) in menu.items.enumerated() where index > 1 {
      menu.removeItem(item)
    }

    // Make the first item less "disabled" since we use it as a label
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
      // NSPopupMenuWindow
      guard let window = (NSApp.windows.last { $0.className.contains("PopupMenu") }) else {
        return Logger.assertFail("Missing popup menu window")
      }

      guard let row = (window.contentView?.firstDescendant { (row: NSTableRowView) in
        row.frame.minY < 10
      }) else {
        return Logger.assertFail("Missing table row view")
      }

      guard let label = (row.firstDescendant { (view: NSTextField) in
        view.stringValue == Localized.Toolbar.tableOfContents
      }) else {
        return Logger.assertFail("Missing table of contents label")
      }

      label.textColor = .secondaryLabelColor
    }

    Task {
      let tableOfContents = await tableOfContents
      tableOfContents?.forEach { info in
        let title = info.title.components(separatedBy: .newlines).first ?? info.title
        let item = menu.addItem(withTitle: title, action: #selector(self.gotoHeader(_:)))
        item.representedObject = info
        item.setAccessibilityLabel(title)
        item.setAccessibilityValue(info.level)

        if info.selected {
          item.setAccessibilityHelp(Localized.General.selected)
        }

        let fontSize = 15.0 - min(3, Double(info.level))
        let attributedTitle = NSMutableAttributedString()

        attributedTitle.append(NSAttributedString(string: info.selected ? "‣" : " ", attributes: [
          .font: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .medium),
        ]))

        attributedTitle.append(NSAttributedString(string: " \(title)", attributes: [
          .font: NSFont.systemFont(ofSize: fontSize, weight: .medium),
        ]))

        item.attributedTitle = attributedTitle
        menu.addItem(.separator())
      }
    }
  }

  @objc func gotoHeader(_ sender: NSMenuItem) {
    guard let headingInfo = sender.representedObject as? HeadingInfo else {
      Logger.assertFail("Failed to get HeadingInfo from sender: \(sender)")
      return
    }

    startTextEditing()
    bridge.toc.gotoHeader(headingInfo: headingInfo)
  }
}
