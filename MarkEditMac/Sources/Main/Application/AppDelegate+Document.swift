//
//  AppDelegate+Document.swift
//  MarkEditMac
//
//  Created by cyan on 1/15/23.
//

import AppKit

@MainActor
extension AppDelegate {
  func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
    switch AppPreferences.General.newWindowBehavior {
    case .openDocument:
      sender.showOpenPanel()
      return false
    case .newDocument:
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
}
