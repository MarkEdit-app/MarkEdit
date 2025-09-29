//
//  EditorViewController+Menu.swift
//  MarkEditMac
//
//  Created by cyan on 12/15/22.
//

import AppKit
import MarkEditKit
import FontPicker

// MARK: - NSMenu Creation

extension EditorViewController {
  var searchOperationsMenuItem: NSMenuItem? {
    guard findPanel.mode != .hidden else {
      return nil
    }

    let menu = NSMenu()
    menu.autoenablesItems = false

    let canSelect = findPanel.numberOfItems > 0
    let canReplace = canSelect && findPanel.mode == .replace

    menu.addItem(withTitle: Localized.Search.selectAll) { [weak self] in
      self?.performSearchOperation(.selectAll)
    }.isEnabled = canSelect

    menu.addItem(withTitle: Localized.Search.selectAllInSelection) { [weak self] in
      self?.performSearchOperation(.selectAllInSelection)
    }.isEnabled = canSelect

    menu.addItem(withTitle: Localized.Search.replaceAll) { [weak self] in
      self?.performSearchOperation(.replaceAll)
    }.isEnabled = canReplace

    menu.addItem(withTitle: Localized.Search.replaceAllInSelection) { [weak self] in
      self?.performSearchOperation(.replaceAllInSelection)
    }.isEnabled = canReplace

    let item = NSMenuItem(title: Localized.Search.searchOperations)
    item.tag = WKContextMenuItemTag.searchMenu.rawValue
    item.submenu = menu
    return item
  }

  @available(macOS 15.1, *)
  var systemWritingToolsMenu: NSMenu? {
    NSApp.appDelegate?.mainEditMenu?.items.first {
      $0.identifier?.rawValue == "__NSTextViewContextSubmenuIdentifierWritingTools"
    }?.submenu
  }
}

// MARK: - NSMenuDelegate

extension EditorViewController: NSMenuDelegate {
  func menuNeedsUpdate(_ menu: NSMenu) {
    updateToolbarItemMenus(menu)
    updateUserDefinedMenus(menu)
  }

  func menuWillOpen(_ menu: NSMenu) {
    presentedMenu = menu
  }

  func menuDidClose(_ menu: NSMenu) {
    DispatchQueue.main.async {
      self.presentedMenu = nil
    }
  }
}

// MARK: - NSMenuItemValidation

extension EditorViewController: NSMenuItemValidation {
  /// Actions that require the existence of a file.
  private static let fileActions = [
    #selector(copyFilePath(_:)),
    #selector(copyFolderPath(_:)),
    #selector(copyPandocCommand(_:)),
    #selector(revealInFinder(_:)),
    #selector(deleteVersionsByDate(_:)),
    #selector(deleteVersionsByCapacity(_:)),
  ]

  func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    // Disable most edit actions for read-only mode
    if isReadOnlyMode {
      guard let menu = menuItem.menu, let delegate = NSApp.appDelegate else {
        return false
      }

      // Enable a few menus and items for "Read Only Mode", mostly navigation related
      if isReadOnlyMode {
        // Table of Contents, Font, Find
        let menus = [delegate.editTableOfContentsMenu, delegate.editFontMenu, delegate.editFindMenu]
        if (menus.contains { menu.isDescendantOf(menu: $0) }) {
          return true
        }

        // Goto to Line, Read Only Mode, Statistics
        let items = [delegate.editGotoLineItem, delegate.editReadOnlyItem, delegate.editStatisticsItem]
        if items.contains(menuItem) {
          return true
        }
      }

      return [
        delegate.mainEditMenu,
        delegate.reopenFileMenu,
        delegate.lineEndingsMenu,
        delegate.textFormatMenu,
      ].allSatisfy { !menu.isDescendantOf(menu: $0) }
    }

    // When webView is not the firstResponder, disable some menus entirely
    if NSApp.keyWindow?.firstResponder != webView {
      let disabledMenus = [
        NSApp.appDelegate?.textFormatMenu,
        NSApp.appDelegate?.editCommandsMenu,
      ]

      if (disabledMenus.contains { menuItem.menu?.isDescendantOf(menu: $0) == true }) {
        return false
      }
    }

    if let action = menuItem.action, Self.fileActions.contains(action) {
      return document?.fileURL != nil
    }

    switch menuItem.action {
    case #selector(resetFontSize(_:)):
      return abs(AppPreferences.Editor.fontSize - FontPicker.defaultFontSize) > .ulpOfOne
    case #selector(makeFontBigger(_:)):
      return AppPreferences.Editor.fontSize < FontPicker.maximumFontSize
    case #selector(makeFontSmaller(_:)):
      return AppPreferences.Editor.fontSize > FontPicker.minimumFontSize
    case #selector(actualSize(_:)):
      return abs(webView.magnification - 1.0) > .ulpOfOne
    case #selector(zoomIn(_:)):
      return webView.magnification < Constants.maximumZoomLevel
    case #selector(zoomOut(_:)):
      return webView.magnification > Constants.minimumZoomLevel
    case #selector(toggleWindowFloating(_:)):
      return view.window?.isKeyWindow == true
    default:
      return true
    }
  }
}

// MARK: - Application

extension EditorViewController {
  @IBAction func terminate(_ sender: Any?) {
    document?.isTerminating = true
    NSApplication.shared.terminate(sender)
  }
}

// MARK: - Developer

extension EditorViewController {
  @IBAction func inspectElement(_ sender: Any?) {
    webView.showInspector()
  }
}

// MARK: - Formatting

extension EditorViewController {

  // MARK: - Headers

  @IBAction func toggleH1(_ sender: Any?) {
    bridge.format.toggleHeading(level: 1)
  }

  @IBAction func toggleH2(_ sender: Any?) {
    bridge.format.toggleHeading(level: 2)
  }

  @IBAction func toggleH3(_ sender: Any?) {
    bridge.format.toggleHeading(level: 3)
  }

  @IBAction func toggleH4(_ sender: Any?) {
    bridge.format.toggleHeading(level: 4)
  }

  @IBAction func toggleH5(_ sender: Any?) {
    bridge.format.toggleHeading(level: 5)
  }

  @IBAction func toggleH6(_ sender: Any?) {
    bridge.format.toggleHeading(level: 6)
  }

  // MARK: - Text Styles

  @IBAction func toggleBold(_ sender: Any?) {
    bridge.format.toggleBold()
  }

  @IBAction func toggleItalic(_ sender: Any?) {
    bridge.format.toggleItalic()
  }

  @IBAction func toggleStrikethrough(_ sender: Any?) {
    bridge.format.toggleStrikethrough()
  }

  // MARK: - Hyper Link

  @IBAction func insertLink(_ sender: Any?) {
    insertHyperLink(prefix: nil)
  }

  @IBAction func insertImage(_ sender: Any?) {
    insertHyperLink(prefix: "!")
  }

  // MARK: - List

  @IBAction func toggleBullet(_ sender: Any?) {
    bridge.format.toggleBullet()
  }

  @IBAction func toggleNumbering(_ sender: Any?) {
    bridge.format.toggleNumbering()
  }

  @IBAction func toggleTodo(_ sender: Any?) {
    bridge.format.toggleTodo()
  }

  // MARK: - Others

  @IBAction func toggleBlockquote(_ sender: Any?) {
    bridge.format.toggleBlockquote()
  }

  @IBAction func toggleInlineCode(_ sender: Any?) {
    bridge.format.toggleInlineCode()
  }

  @IBAction func toggleInlineMath(_ sender: Any?) {
    bridge.format.toggleInlineMath()
  }

  @IBAction func insertCodeBlock(_ sender: Any?) {
    bridge.format.insertCodeBlock()
  }

  @IBAction func insertMathBlock(_ sender: Any?) {
    bridge.format.insertMathBlock()
  }

  @IBAction func insertHorizontalRule(_ sender: Any?) {
    bridge.format.insertHorizontalRule()
  }

  @IBAction func insertTable(_ sender: Any?) {
    bridge.format.insertTable(
      columnName: Localized.Editor.tableColumnName,
      itemName: Localized.Editor.tableItemName
    )
  }
}

// MARK: - Text Find

extension EditorViewController {
  @IBAction func startFind(_ sender: Any?) {
    updateTextFinderMode(.find)
  }

  @IBAction func startReplace(_ sender: Any?) {
    updateTextFinderMode(.replace)
  }

  @IBAction func findSelection(_ sender: Any?) {
    findSelectionInTextFinder()
  }

  @IBAction func findNextMatch(_ sender: Any?) {
    findNextInTextFinder()
  }

  @IBAction func findPreviousMatch(_ sender: Any?) {
    findPreviousInTextFinder()
  }

  @IBAction func selectAllOccurrences(_ sender: Any?) {
    selectAllOccurrences()
  }

  @IBAction func selectNextOccurrence(_ sender: Any?) {
    selectNextOccurrence()
  }

  @IBAction func scrollToSelection(_ sender: Any?) {
    bridge.selection.scrollToSelection()
  }
}

// MARK: - Document

private extension EditorViewController {
  @IBAction func performClose(_ sender: Any?) {
    view.window?.performClose(sender)
  }

  @IBAction func createNewTab(_ sender: Any?) {
    // The easiest way to always create tab regardless of the tabbing mode,
    // just temporarily overwrite the mode to preferred and switch back later.
    let tabbingMode = AppPreferences.Window.tabbingMode
    AppPreferences.Window.tabbingMode = .preferred

    NSDocumentController.shared.newDocument(sender)
    AppPreferences.Window.tabbingMode = tabbingMode
  }

  @IBAction func revealInFinder(_ sender: Any?) {
    guard let fileURL = document?.fileURL else { return }
    NSWorkspace.shared.activateFileViewerSelecting([fileURL])
  }

  @IBAction func copyFilePath(_ sender: Any?) {
    guard let fileURL = document?.fileURL else { return }
    NSPasteboard.general.overwrite(string: fileURL.path)
  }

  @IBAction func copyFolderPath(_ sender: Any?) {
    guard let folderURL = document?.folderURL else { return }
    NSPasteboard.general.overwrite(string: folderURL.path)
  }

  @IBAction func copyPandocCommand(_ sender: Any?) {
    guard let document, let format = (sender as? NSMenuItem)?.identifier?.rawValue else {
      Logger.log(.error, "Failed to copy pandoc command")
      return
    }

    copyPandocCommand(document: document, format: format)
  }

  @IBAction func learnPandoc(_ sender: Any?) {
    NSWorkspace.shared.safelyOpenURL(string: "https://github.com/MarkEdit-app/MarkEdit/wiki/Manual#pandoc")
  }

  @IBAction func deleteVersionsByDate(_ sender: Any?) {
    guard let document, let days = (sender as? NSMenuItem)?.tag else {
      Logger.log(.error, "Failed to delete versions by: \(String(describing: sender))")
      return
    }

    Task {
      await deleteFileVersions(document.otherVersions(olderThanDays: days))
    }
  }

  @IBAction func deleteVersionsByCapacity(_ sender: Any?) {
    guard let document, let maxLength = (sender as? NSMenuItem)?.tag else {
      Logger.log(.error, "Failed to delete versions by: \(String(describing: sender))")
      return
    }

    Task {
      await deleteFileVersions(document.otherVersions(olderThanMaxLength: maxLength))
    }
  }
}

// MARK: - Edit

private extension EditorViewController {
  @IBAction func undo(_ sender: Any?) {
    if let currentInput {
      currentInput.performTextAction(.undo, sender: sender)
    } else {
      NSApp.sendAction(#selector(undo(_:)), to: nil, from: sender)
    }
  }

  @IBAction func redo(_ sender: Any?) {
    if let currentInput {
      currentInput.performTextAction(.redo, sender: sender)
    } else {
      NSApp.sendAction(#selector(redo(_:)), to: nil, from: sender)
    }
  }

  @IBAction func selectWholeDocument(_ sender: Any?) {
    // The default implementation "selectAll" only selects the viewport
    if let currentInput {
      currentInput.performTextAction(.selectAll, sender: sender)
    } else {
      NSApp.sendAction(#selector(selectAll(_:)), to: nil, from: sender)
    }
  }

  @IBAction func gotoLine(_ sender: Any?) {
    showGotoLineWindow(sender)
  }

  @IBAction func openTableOfContents(_ sender: Any?) {
    if let presentedMenu {
      return presentedMenu.cancelTracking()
    }

    // [macOS 14] +enableWindowReuse crash, DispatchQueue would not work
    RunLoop.main.perform {
      Task { @MainActor in
        self.showTableOfContentsMenu()
      }
    }
  }

  @IBAction func selectPreviousSection(_ sender: Any?) {
    startTextEditing()
    bridge.toc.selectPreviousSection()
  }

  @IBAction func selectNextSection(_ sender: Any?) {
    startTextEditing()
    bridge.toc.selectNextSection()
  }

  @IBAction func navigateGoBack(_ sender: Any?) {
    bridge.selection.navigateGoBack()
  }

  @IBAction func resetFontSize(_ sender: Any?) {
    AppPreferences.Editor.fontSize = FontPicker.defaultFontSize
    notifyFontSizeChanged()
  }

  @IBAction func makeFontBigger(_ sender: Any?) {
    AppPreferences.Editor.fontSize = min(FontPicker.maximumFontSize, AppPreferences.Editor.fontSize + 1)
    notifyFontSizeChanged()
  }

  @IBAction func makeFontSmaller(_ sender: Any?) {
    AppPreferences.Editor.fontSize = max(FontPicker.minimumFontSize, AppPreferences.Editor.fontSize - 1)
    notifyFontSizeChanged()
  }

  @IBAction func performEditCommand(_ sender: Any?) {
    guard let identifier = (sender as? NSMenuItem)?.identifier?.rawValue else {
      Logger.log(.error, "Missing identifier to performCommand")
      return
    }

    guard let command = EditCommand(rawValue: identifier) else {
      Logger.log(.error, "Missing command to performCommand")
      return
    }

    bridge.format.performEditCommand(command: command)
  }

  @IBAction func toggleReadOnlyMode(_ sender: Any?) {
    (sender as? NSMenuItem)?.toggle()
    isReadOnlyMode.toggle()
    bridge.config.setReadOnlyMode(enabled: isReadOnlyMode)
  }

  @IBAction func toggleStatistics(_ sender: Any?) {
    // To wait for the menu to reset its state
    DispatchQueue.main.async {
      self.toggleStatisticsPopover(sourceView: self.statisticsSourceView)
    }
  }

  @IBAction func toggleTypewriterMode(_ sender: Any?) {
    AppPreferences.Editor.typewriterMode.toggle()
    setTypewriterMode(enabled: AppPreferences.Editor.typewriterMode)
  }
}

// MARK: - View

private extension EditorViewController {
  @IBAction func actualSize(_ sender: Any?) {
    webView.magnification = 1.0
  }

  @IBAction func zoomIn(_ sender: Any?) {
    webView.magnification = min(Constants.maximumZoomLevel, webView.magnification + 0.1)
  }

  @IBAction func zoomOut(_ sender: Any?) {
    webView.magnification = max(Constants.minimumZoomLevel, webView.magnification - 0.1)
  }
}

// MARK: - Window

private extension EditorViewController {
  @IBAction func toggleWindowFloating(_ sender: Any?) {
    view.window?.level = view.window?.level == .floating ? .normal : .floating
  }
}

// MARK: - Private

private extension EditorViewController {
  enum Constants {
    static let minimumZoomLevel: Double = 1.0
    static let maximumZoomLevel: Double = 3.0
  }

  var currentInput: EditorTextInput? {
    guard view.window?.isKeyWindow == true else {
      return nil
    }

    let textInput = view.window?.firstResponder as? EditorTextInput
    if textInput == nil {
      Logger.log(.info, "The firstResponder is not EditorTextInput")
    }

    return textInput
  }

  func notifyFontSizeChanged() {
    NotificationCenter.default.post(
      name: .fontSizeChanged,
      object: AppPreferences.Editor.fontSize
    )
  }
}
