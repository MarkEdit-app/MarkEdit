//
//  AppDelegate.swift
//  MarkEditMac
//
//  Created by cyan on 12/12/22.

import AppKit
import AppKitExtensions
import Proofing
import SettingsUI

@NSApplicationMain
final class AppDelegate: NSObject, NSApplicationDelegate {
  @IBOutlet weak var mainFileMenu: NSMenu?
  @IBOutlet weak var mainEditMenu: NSMenu?

  @IBOutlet weak var openFileInMenu: NSMenu?
  @IBOutlet weak var reopenFileMenu: NSMenu?
  @IBOutlet weak var lineEndingsMenu: NSMenu?
  @IBOutlet weak var textFormatMenu: NSMenu?
  @IBOutlet weak var formatHeadersMenu: NSMenu?
  @IBOutlet weak var copyPandocCommandMenu: NSMenu?

  @IBOutlet weak var formatBulletItem: NSMenuItem?
  @IBOutlet weak var formatNumberingItem: NSMenuItem?
  @IBOutlet weak var formatTodoItem: NSMenuItem?
  @IBOutlet weak var formatCodeItem: NSMenuItem?
  @IBOutlet weak var formatCodeBlockItem: NSMenuItem?
  @IBOutlet weak var formatMathItem: NSMenuItem?
  @IBOutlet weak var formatMathBlockItem: NSMenuItem?

  @IBOutlet weak var lineEndingsLFItem: NSMenuItem?
  @IBOutlet weak var lineEndingsCRLFItem: NSMenuItem?
  @IBOutlet weak var lineEndingsCRItem: NSMenuItem?

  @IBOutlet weak var editUndoItem: NSMenuItem?
  @IBOutlet weak var editRedoItem: NSMenuItem?

  private var appearanceObservation: NSKeyValueObservation?
  private var settingsWindowController: NSWindowController?

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.appearance = AppPreferences.General.appearance.resolved()
    appearanceObservation = NSApp.observe(\.effectiveAppearance) { _, _ in
      AppTheme.current.updateAppearance()
    }

    UserDefaults.overwriteTextCheckerOnce()
    NSSpellChecker.swizzleCorrectionIndicatorOnce

    NSDocumentController.shared.warmUp()
    EditorReusePool.shared.warmUp()
    EditorStyleSheet.shared.createFile()

    // Initialize this earlier instead of making it lazy,
    // the window size relies on the SwiftUI content view size, it takes time.
    settingsWindowController = SettingsRootViewController.withTabs([
      .editor,
      .assistant,
      .general,
      .window,
    ])
  }

  func application(_ application: NSApplication, open urls: [URL]) {
    if let url = urls.first(where: { $0.host == Grammarly.shared.redirectHost }) {
      Grammarly.shared.completeOAuth(url: url)
    }
  }
}

// MARK: - Private

private extension AppDelegate {
  @IBAction func showPreferences(_ sender: Any?) {
    settingsWindowController?.showWindow(self)
  }

  @IBAction func showHelp(_ sender: Any?) {
    if let url = URL(string: "https://github.com/MarkEdit-app/MarkEdit/wiki") {
      NSWorkspace.shared.open(url)
    }
  }

  @IBAction func openIssueTracker(_ sender: Any?) {
    if let url = URL(string: "https://github.com/MarkEdit-app/MarkEdit/issues") {
      NSWorkspace.shared.open(url)
    }
  }
}
