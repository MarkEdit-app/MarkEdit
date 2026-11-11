//
//  AppDelegate+Document.swift
//  MarkEditMac
//
//  Created by cyan on 1/15/23.
//

import AppKit
import MarkEditKit

@MainActor
extension AppDelegate {
  var currentDocument: EditorDocument? {
    currentEditor?.document
  }

  var currentEditor: EditorViewController? {
    NSApp.currentEditor
  }

  func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
    // AppKit can request a default window before an explicit document finishes presenting
    guard !NSDocumentController.shared.hasPendingDocumentPresentation else {
      return false
    }

    return shouldOpenOrCreateDocument() && openOrCreateDocument(sender: sender)
  }

  func applicationOpenUntitledFile(_ sender: NSApplication) -> Bool {
    do {
      States.untitledDocument = try NSDocumentController.shared.openUntitledDocumentAndDisplay(true)
      States.untitledFileOpenedDate = Date.timeIntervalSinceReferenceDate
      return true
    } catch {
      sender.presentError(error)
      return false
    }
  }

  func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
    let menu = NSMenu()

    // Keep explicit actions available when they aren't the default behavior
    let behavior = AppPreferences.General.newWindowBehavior
    if behavior != .newDocument {
      menu.addItem(withTitle: Localized.Document.newDocument) {
        NSDocumentController.shared.newDocument(nil)
        NSApp.activate(ignoringOtherApps: true)
      }
    }

    if behavior != .openDocument {
      menu.addItem(withTitle: Localized.Document.openDocument) {
        sender.showOpenPanel()
      }
    }

    if behavior != .quickSearch {
      menu.addItem(withTitle: Localized.QuickSearch.title) { [weak self] in
        self?.quickSearch(nil)
        NSApp.activate(ignoringOtherApps: true)
      }
    }

    return menu
  }

  func createNewFile(fileName: String? = nil, initialContent: String? = nil, isIntent: Bool = false) {
    let controller = NSDocumentController.shared
    let document: NSDocument

    // Activating the app also creates a new file if new window behavior is `newDocument`,
    // prevent duplicate creation from Shortcuts like `CreateNewDocumentIntent`.
    if isIntent && (Date.timeIntervalSinceReferenceDate - States.untitledFileOpenedDate <= 0.2),
       let untitledDocument = States.untitledDocument,
       untitledDocument.fileURL == nil && (controller.documents.contains { $0 === untitledDocument }) {
      document = untitledDocument
    } else {
      do {
        document = try controller.openUntitledDocumentAndDisplay(false)
        document.makeWindowControllers()
      } catch {
        NSApp.presentError(error)
        return
      }
    }

    States.untitledDocument = nil
    guard let document = document as? EditorDocument else {
      return Logger.assertFail("Unexpected document type: \(document)")
    }

    guard let editor = document.windowControllers.first?.contentViewController as? EditorViewController else {
      return Logger.assertFail("Missing editor for new document")
    }

    if isIntent {
      NSApp.activate(ignoringOtherApps: true)
    }

    document.externalFilename = fileName
    if let initialContent {
      editor.prepareInitialContent(initialContent)
    }

    document.showWindows()
  }

  func openFile(queryDict: [String: String]?) {
    if let filePath = queryDict?["path"] {
      NSWorkspace.shared.openOrReveal(url: URL(filePath: filePath))
    } else {
      NSApp.showOpenPanel()
    }
  }

  func createNewFile(queryDict: [String: String]?) {
    let fileName = queryDict?["filename"]
    let initialContent = queryDict?["initial-content"]
    createNewFile(fileName: fileName, initialContent: initialContent)
  }

  func toggleDocumentWindowVisibility() {
    // Order out immaterial windows like settings, about...
    for window in NSApp.windows where !(window is EditorWindow) {
      window.orderOut(nil)
    }

    let windows = NSApp.windows.filter {
      $0 is EditorWindow
    }

    if windows.isEmpty {
      // Open a new window if we don't have any editor windows
      openOrCreateDocument(sender: NSApp)
    } else if (windows.contains { $0.isKeyWindow }) {
      // Hide the app if there was already a key editor window
      NSApp.hide(nil)
    } else {
      // Ensure one editor window is key and ordered front, if exists, called after NSApp.activate
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
        let windows = NSApp.windows.filter { $0 is EditorWindow }
        if (windows.allSatisfy { !$0.isKeyWindow }) {
          windows.first?.makeKeyAndOrderFront(nil)
        }
      }
    }

    NSApp.activate(ignoringOtherApps: true)
  }
}

// MARK: - Private

private extension AppDelegate {
  enum States {
    @MainActor static var openPanelShownDate: TimeInterval = 0
    @MainActor static var untitledFileOpenedDate: TimeInterval = 0
    @MainActor static weak var untitledDocument: NSDocument?
  }

  @discardableResult
  func openOrCreateDocument(sender: NSApplication) -> Bool {
    switch AppPreferences.General.newWindowBehavior {
    case .openDocument:
      // The system occasionally runs this twice in a row, prevent duplicate panels
      let currentDate = Date.timeIntervalSinceReferenceDate
      if currentDate - States.openPanelShownDate > 0.2 {
        States.openPanelShownDate = currentDate
        sender.showOpenPanel()
      }

      return false
    case .quickSearch:
      quickSearch(sender)
      return false
    case .newDocument:
      return true
    }
  }
}
