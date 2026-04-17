//
//  AppDelegate+ClosedTab.swift
//  MarkEditMac
//
//  Created by cyan on 4/16/26.
//

import AppKit
import MarkEditKit

// MARK: - Closed Tab

extension AppDelegate {
  private enum ReopenStates {
    @MainActor static var inFlightCount = 0
    @MainActor static var savedAllowsAutomaticWindowTabbing: Bool?
  }

  @IBAction func reopenClosedTab(_ sender: Any?) {
    guard let entry = EditorClosedTabHistory.shared.pop() else {
      NSSound.beep()
      return
    }

    // Resolve target window based on the current tabbing mode preference.
    //
    // .disallowed: always open standalone.
    // .preferred: open as a tab when a suitable target window exists.
    // .automatic: respect original state.
    let targetWindow: EditorWindow? = {
      if AppPreferences.Window.tabbingMode == .disallowed {
        return nil
      }

      if AppPreferences.Window.tabbingMode == .preferred || !entry.wasStandalone {
        if let source = entry.sourceWindow as? EditorWindow {
          return source
        }

        return (NSApp.keyWindow as? EditorWindow) ?? (NSApp.mainWindow as? EditorWindow)
      }

      return nil
    }()

    // openDocument(display:true) normally auto-joins the key window's tab group.
    // Temporarily disable this so the window opens standalone, then we manually
    // addTabbedWindow to the correct target. Counter handles rapid Cmd+Shift+T.
    if ReopenStates.inFlightCount == 0 {
      ReopenStates.savedAllowsAutomaticWindowTabbing = NSWindow.allowsAutomaticWindowTabbing
      NSWindow.allowsAutomaticWindowTabbing = false
    }

    ReopenStates.inFlightCount += 1
    NSDocumentController.shared.openDocument(
      withContentsOf: entry.url,
      display: true
    ) { document, _, error in
      ReopenStates.inFlightCount -= 1
      if ReopenStates.inFlightCount == 0 {
        NSWindow.allowsAutomaticWindowTabbing = ReopenStates.savedAllowsAutomaticWindowTabbing ?? true
        ReopenStates.savedAllowsAutomaticWindowTabbing = nil
      }

      if let error {
        NSSound.beep()
        Logger.log(.error, "Failed to reopen closed tab: \(error.localizedDescription)")

        EditorClosedTabHistory.shared.push(
          entry.url,
          tabIndex: entry.tabIndex,
          sourceWindow: entry.sourceWindow,
          wasStandalone: entry.wasStandalone
        )

        return
      }

      guard let editorDocument = document as? EditorDocument else {
        return
      }

      Task { @MainActor in
        guard let newWindow = editorDocument.windowControllers.first?.window else {
          return
        }

        if let targetWindow {
          targetWindow.addTabbedWindow(newWindow, ordered: .above)
          editorDocument.restoreTabPosition(tabIndex: entry.tabIndex, relativeTo: targetWindow)
        }
      }
    }
  }
}
