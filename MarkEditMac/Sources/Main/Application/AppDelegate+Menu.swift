//
//  AppDelegate+Menu.swift
//  MarkEditMac
//
//  Created by cyan on 1/15/23.
//

import AppKit
import MarkEditKit

// MARK: - NSMenuDelegate

extension AppDelegate: NSMenuDelegate {
  var activeWritingToolsItem: NSMenuItem? {
    mainEditMenu?.items.first {
      $0.identifier?.rawValue == "__NSTextViewContextSubmenuIdentifierWritingTools"
    }
  }

  func menuNeedsUpdate(_ menu: NSMenu) {
    switch menu {
    case mainFileMenu:
      reconfigureMainFileMenu(document: currentDocument)
    case mainEditMenu:
      reconfigureMainEditMenu(document: currentDocument)
    case mainExtensionsMenu:
      reconfigureMainExtensionsMenu(document: currentDocument)
    case mainWindowMenu:
      reconfigureMainWindowMenu(window: NSApp.keyWindow)
    case openFileInMenu:
      reconfigureOpenFileInMenu(document: currentDocument)
    case reopenFileMenu:
      reconfigureReopenFileMenu(document: currentDocument)
    case bookmarksMenu:
      reconfigureBookmarksMenu(menu)
    case lineEndingsMenu:
      reconfigureLineEndingsMenu(document: currentDocument)
    default:
      break
    }
  }

  func reconfigureMainWindowMenu(window: NSWindow?) {
    windowFloatingItem?.isEnabled = window is EditorWindow
    windowFloatingItem?.setOn(window?.level == .floating)
  }
}

// MARK: - NSMenuItemValidation

extension AppDelegate: NSMenuItemValidation {
  func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    switch menuItem.action {
    case #selector(launchSafeMode(_:)):
      return !AppCustomization.isSafeMode
    case #selector(newFileFromClipboard(_:)):
      return NSPasteboard.general.hasText
    case #selector(reopenClosedTab(_:)):
      return EditorClosedTabHistory.shared.hasEntries
    default:
      return true
    }
  }
}

// MARK: - Private

private extension AppDelegate {
  func reconfigureMainFileMenu(document: EditorDocument?) {
    [openFileInMenu, reopenFileMenu, lineEndingsMenu].forEach {
      $0?.superMenuItem?.isEnabled = document?.fileURL != nil
    }
  }

  func reconfigureMainEditMenu(document: EditorDocument?) {
    Task { @MainActor in
      guard let document else {
        return
      }

      editUndoItem?.isEnabled = await document.canUndo
      editRedoItem?.isEnabled = await document.canRedo
      editPasteItem?.isEnabled = NSPasteboard.general.hasText
    }

    // [macOS 27] Always enable "Writing Tools"
    if #available(macOS 27.0, *), AppDesign.forceWritingTools {
      // Prevent duplicate items
      editWritingToolsItem?.isHidden = !(activeWritingToolsItem?.isHidden ?? true)

      // Copy properties from `standardWritingToolsMenuItem`
      let systemItem = NSMenuItem.systemWritingToolsItem
      editWritingToolsItem?.submenu = systemItem?.submenu?.copiedMenu
      editWritingToolsItem?.title = systemItem?.title ?? Localized.WritingTools.featureName
      editWritingToolsItem?.image = AppWritingTools.affordanceIcon
    }

    editTypewriterItem?.setOn(AppPreferences.Editor.typewriterMode)
  }

  func reconfigureMainExtensionsMenu(document: EditorDocument?) {
    mainExtensionsMenu?.items.forEach {
      let isEnabled = $0.target === NSApp.appDelegate || document != nil
      $0.setEnabledRecursively(isEnabled: isEnabled)
    }

    if let menu = mainExtensionsMenu {
      currentEditor?.updateUserDefinedMenus(menu)
    }
  }

  @MainActor
  func reconfigureOpenFileInMenu(document: EditorDocument?) {
    openFileInMenu?.removeAllItems()

    // Disabled or not able to find the document, just leave the menu empty
    guard let fileURL = document?.fileURL else {
      return
    }

    // Basically, we wouldn't expect to see "MarkEdit.app"
    let appURLs = NSWorkspace.shared.urlsForApplications(toOpen: fileURL).filter {
      $0.lastPathComponent != Bundle.main.bundleURL.lastPathComponent
    }

    appURLs.forEach { appURL in
      let item = openFileInMenu?.addItem(withTitle: appURL.localizedName) {
        NSWorkspace.shared.open(
          [fileURL],
          withApplicationAt: appURL,
          configuration: NSWorkspace.OpenConfiguration(),
          completionHandler: nil
        )
      }

      let icon = NSWorkspace.shared.icon(forFile: appURL.path)
      item?.image = icon.resized(with: CGSize(width: 16, height: 16))
      item?.ensureImageVisibility()
    }
  }

  func reconfigureReopenFileMenu(document: EditorDocument?) {
    reopenFileMenu?.removeAllItems()

    // Disabled or not able to find the document, just leave the menu empty
    guard document?.fileURL != nil else {
      return
    }

    for encoding in EditorTextEncoding.allCases {
      let item = reopenFileMenu?.addItem(withTitle: encoding.description, action: #selector(EditorViewController.reopenWithEncoding(_:)))
      item?.representedObject = encoding

      if EditorTextEncoding.groupingCases.contains(encoding) {
        reopenFileMenu?.addItem(.separator())
      }
    }
  }

  func reconfigureLineEndingsMenu(document: EditorDocument?) {
    Task { @MainActor in
      guard let lineEndings = await document?.lineEndings else {
        return
      }

      lineEndingsLFItem?.setOn(lineEndings == .lf)
      lineEndingsCRLFItem?.setOn(lineEndings == .crlf)
      lineEndingsCRItem?.setOn(lineEndings == .cr)
      lineEndingsMenu?.reloadItems()
    }
  }

  func reconfigureBookmarksMenu(_ menu: NSMenu) {
    menu.removeAllItems()
    menu.autoenablesItems = false

    let bookmarks = bookmarkStore.load()
    let urls = Array(Set(bookmarks.compactMap { $0.url?.standardizedFileURL }))
    var displayedURLs = Set<URL>()

    for (index, bookmark) in bookmarks.enumerated() {
      if let url = bookmark.url, !displayedURLs.insert(url.standardizedFileURL).inserted {
        continue
      }

      let title = bookmark.url.map {
        $0.standardizedFileURL.displayTitle(among: urls)
      } ?? String(format: Localized.Bookmarks.unavailable, index + 1)

      let item = menu.addItem(withTitle: title)
      item.toolTip = bookmark.url?.path ?? bookmark.error?.localizedDescription
      if let url = bookmark.url {
        item.setAccessibilityLabel(url.path)
        item.image = NSWorkspace.shared.icon(forFile: url.path).resized(with: CGSize(width: 16, height: 16))
        item.ensureImageVisibility()
      }

      let submenu = NSMenu(title: title)
      submenu.autoenablesItems = false

      let reveal = submenu.addItem(withTitle: Localized.Bookmarks.revealInFinder) {
        if let url = bookmark.url {
          NSWorkspace.shared.activateFileViewerSelecting([url])
        }
      }

      reveal.isEnabled = bookmark.url != nil
      submenu.addItem(withTitle: Localized.Bookmarks.revokeBookmark) { [weak self] in
        guard let self else { return }
        self.performBookmarkChange {
          try self.bookmarkStore.revoke(bookmark)
        }
      }

      item.submenu = submenu
    }

    if !menu.items.isEmpty {
      menu.addItem(.separator())
    }

    let addItem = menu.addItem(withTitle: Localized.Bookmarks.addBookmarks, action: #selector(addBookmarks(_:)))
    addItem.target = self

    let revokeAllItem = menu.addItem(withTitle: Localized.Bookmarks.revokeAll) { [weak self] in
      self?.bookmarkStore.revokeAll()
    }

    revokeAllItem.isEnabled = !bookmarks.isEmpty
  }
}

// MARK: - Actions

extension AppDelegate {
  @IBAction func newFileFromClipboard(_ sender: Any?) {
    createNewFile(initialContent: NSPasteboard.general.string)
  }

  @IBAction func manageExtensions(_ sender: Any?) {
    ExtensionsWindowController.shared.present()
  }
}

// MARK: - Private

private extension AppDelegate {
  @IBAction func launchSafeMode(_ sender: Any?) {
    guard !AppCustomization.isSafeMode else {
      return
    }

    NSApp.relaunchSafely(sender, safeMode: true)
  }

  @IBAction func checkForUpdates(_ sender: Any?) {
    Task {
      await AppUpdater.checkForUpdates(explicitly: true)
    }
  }

  @IBAction func openDocumentsFolder(_ sender: Any?) {
    NSWorkspace.shared.open(.documentsDirectory)
  }

  @IBAction func addBookmarks(_ sender: Any?) {
    NSApp.closeOpenPanels()
    Task {
      await addBookmarks()
    }
  }

  @IBAction func saveAllDocuments(_ sender: Any?) {
    NSDocumentController.shared.saveAllDocuments(nil)
  }

  @IBAction func openDevelopmentGuide(_ sender: Any?) {
    NSWorkspace.shared.safelyOpenURL(string: "https://github.com/MarkEdit-app/MarkEdit/wiki/Development")
  }

  @IBAction func openCustomizationGuide(_ sender: Any?) {
    NSWorkspace.shared.safelyOpenURL(string: "https://github.com/MarkEdit-app/MarkEdit/wiki/Customization")
  }

  @IBAction func showHelp(_ sender: Any?) {
    NSWorkspace.shared.safelyOpenURL(string: "https://github.com/MarkEdit-app/MarkEdit/wiki")
  }

  @IBAction func openIssueTracker(_ sender: Any?) {
    NSWorkspace.shared.safelyOpenURL(string: "https://github.com/MarkEdit-app/MarkEdit/issues")
  }

  @IBAction func openVersionHistory(_ sender: Any?) {
    NSWorkspace.shared.safelyOpenURL(string: "https://github.com/MarkEdit-app/MarkEdit/releases")
  }

  @IBAction func openUpdateBehavior(_ sender: Any?) {
    NSWorkspace.shared.safelyOpenURL(string: "https://github.com/MarkEdit-app/MarkEdit/wiki/Customization#generalupdatebehavior")
  }
}
