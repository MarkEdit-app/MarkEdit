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
    let sourceView =
      // Relative to the toolbar item
      view.window?.toolbarButton(with: statisticsItem.itemIdentifier) ??
      // Relative to the document title view
      view.window?.titlebarDocumentTitleView

    Logger.assert(sourceView != nil, "Missing source view")
    return sourceView
  }

  private enum Constants {
    static let tableOfContentsMenuIdentifier = NSUserInterfaceItemIdentifier("tableOfContentsMenu")
    static let tableOfContentsMinimumWidth: Double = 160
  }

  func updateToolbarItemMenus(_ menu: NSMenu) {
    if menu.identifier == Constants.tableOfContentsMenuIdentifier {
      Task { @MainActor in
        await updateTableOfContentsMenu(menu)
      }
    }
  }

  func showTableOfContentsMenu() {
    bridge.core.handleFocusLost()
    presentedPopover?.close()

    // Pop up the menu relative to the toolbar item
    if let tableOfContentsMenuButton {
      return RunLoop.main.perform(inModes: [.default, .eventTracking]) {
        tableOfContentsMenuButton.performClick(nil)
      }
    }

    // Pop up the menu relative to the document title view
    if let menu = (tableOfContentsItem as? NSMenuToolbarItem)?.menu {
      Task { @MainActor in
        await updateTableOfContentsMenu(menu)
        if let sourceView = view.window?.titlebarDocumentTitleView {
          menu.popUp(
            positioning: nil,
            at: CGPoint(x: sourceView.bounds.minX, y: sourceView.bounds.maxY + 15),
            in: sourceView
          )
        } else {
          Logger.assertFail("Missing document title view")
        }
      }

      return
    }
  }

  func customItem(with identifier: NSToolbarItem.Identifier) -> CustomToolbarItem? {
    AppRuntimeConfig.customToolbarItems.first {
      $0.identifier.rawValue == identifier.rawValue
    }
  }

  func extensionItem(with identifier: NSToolbarItem.Identifier) -> WebToolbarItem? {
    guard let id = ExtensionToolbarController.id(for: identifier) else {
      return nil
    }

    return userDefinedToolbarItems.first { $0.id == id }
  }

  func addToolbarItems(_ items: [WebToolbarItem]) {
    var registered = [WebToolbarItem]()
    for spec in items {
      guard !(userDefinedToolbarItems.contains { $0.id == spec.id }) else {
        Logger.log(.error, "Duplicate toolbar item ID: \(spec.id)")
        continue
      }

      guard ExtensionToolbarController.isValid(spec, editor: self) else {
        Logger.log(.error, "Invalid toolbar item: \(spec.id)")
        continue
      }

      userDefinedToolbarItems.append(spec)
      registered.append(spec)
    }

    ExtensionToolbarController.cacheDefaults(registered)
    updateExtensionToolbarItems()
  }

  func invalidateToolbarItem(_ id: String) {
    guard (userDefinedToolbarItems.contains { $0.id == id }) else {
      Logger.log(.error, "Unknown toolbar item ID: \(id)")
      return
    }

    let identifier = ExtensionToolbarController.identifier(for: id)
    for item in viewIfLoaded?.window?.toolbar?.items ?? [] where item.itemIdentifier == identifier {
      item.extensionToolbarController?.invalidateState()
    }
  }

  func updateExtensionToolbarItems() {
    guard let toolbar = viewIfLoaded?.window?.toolbar, toolbar.delegate === self else {
      return
    }

    if hasFinishedLoading {
      // Document-end scripts have finished registering their toolbar items
      for (index, item) in toolbar.items.enumerated().reversed() {
        let identifier = item.itemIdentifier
        guard ExtensionToolbarController.id(for: identifier) != nil,
              extensionItem(with: identifier) == nil else {
          continue
        }

        toolbar.removeItem(at: index)
      }
    }

    var introduced = AppPreferences.Window.introducedToolbarItemIDs
    let previous = introduced

    // Prepend to the leading end
    var insertionIndex = toolbar.items.prefix {
      ExtensionToolbarController.id(for: $0.itemIdentifier) != nil
    }.count

    for spec in userDefinedToolbarItems {
      let identifier = ExtensionToolbarController.identifier(for: spec.id)
      if let index = (toolbar.items.firstIndex { $0.itemIdentifier == identifier }) {
        let item = toolbar.items[index]
        if !ExtensionToolbarController.matches(item, spec: spec) {
          toolbar.removeItem(at: index)
          toolbar.insertItem(withItemIdentifier: identifier, at: index)
        } else if item.extensionToolbarController == nil {
          ExtensionToolbarController.configure(item, spec: spec, editor: self)
        }
      } else if !introduced.contains(spec.id), spec.initialPlacement == .toolbar {
        toolbar.insertItem(withItemIdentifier: identifier, at: insertionIndex)
        insertionIndex += 1
      }

      if spec.initialPlacement == .customization ||
        (toolbar.items.contains { $0.itemIdentifier == identifier && $0.extensionToolbarController != nil }) {
        introduced.insert(spec.id)
      }
    }

    if introduced != previous {
      AppPreferences.Window.introducedToolbarItemIDs = introduced
    }
  }
}

// MARK: - NSToolbarDelegate

extension EditorViewController: NSToolbarDelegate {
  func toolbarWillAddItem(_ notification: Notification) {
    guard let (toolbar, item, spec) = notification.extensionToolbarSpec(for: self) else {
      return
    }

    // Palette items can arrive with stale state or without copied associated objects
    if item.extensionToolbarController == nil {
      ExtensionToolbarController.configure(item, spec: spec, editor: self)
    }

    item.extensionToolbarController?.didInsert(into: toolbar)
  }

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
      default:
        if let spec = extensionItem(with: itemIdentifier) {
          return ExtensionToolbarController.makeToolbarItem(spec: spec, editor: self)
        }

        if !hasFinishedLoading, ExtensionToolbarController.id(for: itemIdentifier) != nil {
          return ExtensionToolbarController.makeCachedToolbarItem(
            identifier: itemIdentifier,
            editor: self
          ) ?? ExtensionToolbarController.makePlaceholder(identifier: itemIdentifier)
        }

        if let customItem = customItem(with: itemIdentifier) {
          return .with(identifier: itemIdentifier, customItem: customItem)
        }

        return nil
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
    let registered = userDefinedToolbarItems.map {
      ExtensionToolbarController.identifier(for: $0.id)
    }

    let pending = toolbar.itemIdentifiers.filter {
      !hasFinishedLoading && ExtensionToolbarController.id(for: $0) != nil && !registered.contains($0)
    }

    return [
      NSToolbarItem.Identifier.allItems,
      AppRuntimeConfig.customToolbarItems.map(\.identifier),
      registered,
      pending,
    ].flatMap { $0 }
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

    let label = NSMenuItem.sectionHeader(title: Localized.Toolbar.tableOfContents)
    menu.items = [label, .separator()]
    menu.autoenablesItems = false

    return .with(identifier: .tableOfContents, menu: menu)
  }

  var formatHeadersItem: NSToolbarItem {
    .with(identifier: .formatHeaders, menu: NSApp.appDelegate?.formatHeadersMenu?.copiedMenu)
  }

  var toggleBoldItem: NSToolbarItem {
    .with(identifier: .toggleBold) { [weak self] in
      self?.toggleBold(nil)
    }
  }

  var toggleItalicItem: NSToolbarItem {
    .with(identifier: .toggleItalic) { [weak self] in
      self?.toggleItalic(nil)
    }
  }

  var toggleStrikethroughItem: NSToolbarItem {
    .with(identifier: .toggleStrikethrough) { [weak self] in
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
    if let menu = NSApp.appDelegate?.activeWritingToolsItem?.submenu {
      return .with(identifier: .writingTools, menu: menu.copiedMenu)
    }

    return nil
  }

  func updateTableOfContentsMenu(_ menu: NSMenu) async {
    // Remove existing items, the first two are placeholders that we want to keep
    for (index, item) in menu.items.enumerated() where index > 1 {
      menu.removeItem(item)
    }

    let tableOfContents = await tableOfContents
    let baseLevel = tableOfContents?.map { $0.level }.min() ?? 1

    tableOfContents?.forEach { info in
      let title = String(repeating: " ", count: (info.level - baseLevel) * 2) + info.title
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

  @objc func gotoHeader(_ sender: NSMenuItem) {
    guard let headingInfo = sender.representedObject as? HeadingInfo else {
      Logger.assertFail("Failed to get HeadingInfo from sender: \(sender)")
      return
    }

    startTextEditing()
    bridge.toc.gotoHeader(headingInfo: headingInfo)
  }
}

private extension Notification {
  @MainActor
  func extensionToolbarSpec(for editor: EditorViewController) -> (
    toolbar: NSToolbar,
    item: NSToolbarItem,
    spec: WebToolbarItem
  )? {
    // https://developer.apple.com/documentation/appkit/nstoolbar/willadditemnotification
    guard let toolbar = object as? NSToolbar,
          let item = userInfo?[NSToolbarUserInfoKey.itemKey.rawValue] as? NSToolbarItem,
          let spec = editor.extensionItem(with: item.itemIdentifier) else {
      return nil
    }

    return (toolbar, item, spec)
  }
}
