//
//  AppDelegate+Document.swift
//  MarkEditMac
//
//  Created by cyan on 1/15/23.
//

import AppKit

extension AppDelegate {
  func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
    switch AppPreferences.General.newWindowBehavior {
    case .openDocument:
      // Prefer to see the openPanel asap, warm-up can be delayed
      DispatchQueue.afterDelay(seconds: 0.5) {
        EditorReusePool.shared.warmUp()
      }

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
      }
    case .newDocument:
      menu.addItem(withTitle: Localized.Document.openDocument) {
        NSApplication.shared.showOpenPanel()
      }
    }

    return menu
  }
}
