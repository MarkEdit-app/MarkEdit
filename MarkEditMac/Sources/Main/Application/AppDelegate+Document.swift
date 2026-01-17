//
//  AppDelegate+Document.swift
//  MarkEditMac
//
//  Created by cyan on 1/15/23.
//

import AppKit

@MainActor
extension AppDelegate {
  var currentDocument: EditorDocument? {
    currentEditor?.document
  }

  var currentEditor: EditorViewController? {
    (NSApp as? Application)?.currentEditor
  }

  func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
    shouldOpenOrCreateDocument() && openOrCreateDocument(sender: sender)
  }

  func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
    let menu = NSMenu()

    // Only show the secondary option based on the preference
    switch AppPreferences.General.newWindowBehavior {
    case .openDocument:
      menu.addItem(withTitle: Localized.Document.newDocument) {
        NSDocumentController.shared.newDocument(nil)
        NSApp.activate(ignoringOtherApps: true)
      }
    case .newDocument:
      menu.addItem(withTitle: Localized.Document.openDocument) {
        sender.showOpenPanel()
      }
    }

    return menu
  }

  func createNewFile(fileName: String? = nil, initialContent: String? = nil, isIntent: Bool = false) {
    // In EditorDocument, this is used as an external filename
    AppDocumentController.suggestedFilename = fileName

    // Activating the app also creates a new file if new window behavior is `newDocument`,
    // prevent duplicate creation from Shortcuts like `CreateNewDocumentIntent`.
    if !isIntent || (Date.timeIntervalSinceReferenceDate - States.untitledFileOpenedDate > 0.2) {
      NSDocumentController.shared.newDocument(nil)
    }

    if isIntent {
      NSApp.activate(ignoringOtherApps: true)
    }

    if let initialContent {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
        self.currentEditor?.prepareInitialContent(initialContent)
      }
    }
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
        if windows.allSatisfy({ !$0.isKeyWindow }) {
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
    case .newDocument:
      States.untitledFileOpenedDate = Date.timeIntervalSinceReferenceDate
      return true
    }
  }
}
