//
//  AppDelegate+Menu.swift
//  MarkEditMac
//
//  Created by cyan on 1/15/23.
//

import AppKit
import MarkEditKit

extension AppDelegate: NSMenuDelegate {
  func menuNeedsUpdate(_ menu: NSMenu) {
    switch menu {
    case mainFileMenu:
      let noDoc = activeDocument?.fileURL == nil
      openFileInMenu?.superMenuItem?.isHidden = noDoc
      reopenFileMenu?.superMenuItem?.isHidden = noDoc
      lineEndingsMenu?.superMenuItem?.isHidden = noDoc
    case mainEditMenu:
      reconfigureMainEditMenu(document: activeDocument)
    case mainWindowMenu:
      reconfigureMainWindowMenu(document: activeDocument)
    case openFileInMenu:
      reconfigureOpenFileInMenu(document: activeDocument)
    case reopenFileMenu:
      reconfigureReopenFileMenu(document: activeDocument)
    case lineEndingsMenu:
      reconfigureLineEndingsMenu(document: activeDocument)
    default:
      break
    }
  }
}

// MARK: - Private

private extension AppDelegate {
  var activeDocument: EditorDocument? {
    activeEditorController?.document
  }

  var activeEditorController: EditorViewController? {
    NSApp.mainWindow?.contentViewController as? EditorViewController
  }

  func reconfigureMainEditMenu(document: EditorDocument?) {
    Task { @MainActor in
      guard let document else {
        return
      }

      editUndoItem?.isEnabled = await document.canUndo
      editRedoItem?.isEnabled = await document.canRedo
    }

    // [macOS 15] The system one doesn't work for WKWebView
    if #available(macOS 15.1, *), let item = mainEditMenu?.items.first(where: {
      $0.identifier?.rawValue == "__NSTextViewContextSubmenuIdentifierWritingTools"
    }) {
      let isEnabled = activeEditorController?.webView.isFirstResponder == true
      item.submenu = activeEditorController?.customWritingToolsMenu
      item.submenu?.autoenablesItems = false
      item.submenu?.items.forEach { $0.isEnabled = isEnabled }
    }
  }

  func reconfigureMainWindowMenu(document: EditorDocument?) {
    windowFloatingItem?.isEnabled = NSApp.keyWindow is EditorWindow
    windowFloatingItem?.setOn(NSApp.keyWindow?.level == .floating)
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
}
