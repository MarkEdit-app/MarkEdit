//
//  AppDelegate+Document.swift
//  MarkEditMac
//
//  Created by cyan on 1/15/23.
//

import AppKit

@MainActor
extension AppDelegate {
  enum States {
    @MainActor static var untitledFileOpenedDate: TimeInterval = 0
  }

  func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
    switch AppPreferences.General.newWindowBehavior {
    case .openDocument:
      sender.showOpenPanel()
      return false
    case .newDocument:
      States.untitledFileOpenedDate = Date.timeIntervalSinceReferenceDate
      return true
    }
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
        NSApplication.shared.showOpenPanel()
      }
    }

    return menu
  }

  func createUntitledFileIfNeeded() {
    // Activating the app also creates a new file if new window behavior is `newDocument`,
    // prevent duplicate creation from Shortcuts like `CreateNewDocumentIntent`.
    guard Date.timeIntervalSinceReferenceDate - States.untitledFileOpenedDate > 0.1 else {
      return
    }

    NSDocumentController.shared.newDocument(nil)
  }
}
