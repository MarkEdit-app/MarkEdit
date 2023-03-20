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

    EditorReusePool.shared.warmUp()
    EditorCustomization.createFiles()

    // Initialize this earlier instead of making it lazy,
    // the window size relies on the SwiftUI content view size, it takes time.
    settingsWindowController = SettingsRootViewController.withTabs([
      .editor,
      .assistant,
      .general,
      .window,
    ])

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(windowDidResignKey(_:)),
      name: NSWindow.didResignKeyNotification,
      object: nil
    )
  }

  func application(_ application: NSApplication, open urls: [URL]) {
    if let url = urls.first(where: { $0.host == Grammarly.shared.redirectHost }) {
      Grammarly.shared.completeOAuth(url: url)
    }
  }
}

// MARK: - Private

private extension AppDelegate {
  @objc private func windowDidResignKey(_ notification: Notification) {
    // Cancel completion when an editor is no longer the key window
    if let editor = (notification.object as? NSWindow)?.contentViewController as? EditorViewController {
      editor.cancelCompletion()
    }

    // To reduce the glitches between switching windows,
    // close openPanel once we don't have any key windows.
    //
    // Delay because there's no keyWindow during window transitions.
    DispatchQueue.afterDelay(seconds: 0.5) {
      if NSApp.windows.allSatisfy({ !$0.isKeyWindow }) {
        NSApp.closeOpenPanels()
      }
    }
  }

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
