//
//  EditorWindowController.swift
//  MarkEditMac
//
//  Created by cyan on 12/12/22.
//

import AppKit

final class EditorWindowController: NSWindowController, NSWindowDelegate {
  var autosavedFrame: CGRect?
  var needsUpdateFocus = false

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    shouldCascadeWindows = true
  }

  override func windowDidLoad() {
    super.windowDidLoad()
    window?.minSize = CGSize(width: 240, height: 0)
    window?.backgroundColor = .controlBackgroundColor

    windowFrameAutosaveName = "Editor"
    window?.setFrameUsingName(windowFrameAutosaveName)
    saveWindowRect()
  }

  func windowDidBecomeMain(_ notification: Notification) {
    NSApplication.shared.closeOpenPanels()
  }

  func windowDidResignMain(_ notification: Notification) {
    if AppPreferences.Editor.showLineNumbers {
      // In theory, this is not indeed, but we've seen wrong state without this
      editorViewController?.bridge.core.handleMouseExited(clientX: 0, clientY: 0)
    }
  }

  func windowDidBecomeKey(_ notification: Notification) {
    if needsUpdateFocus {
      editorViewController?.refreshEditFocus()
      needsUpdateFocus = false
    }

    // The shared "field editor" tends to hold focus,
    // manually resign the focus to ensure cmd-f responds correctly.
    for editor in EditorPreloader.shared.viewControllers() where editor !== editorViewController {
      editor.resignFindPanelFocus()
    }

    // The main menu is a singleton, we need to update the menu items for the active editor
    editorViewController?.resetUserDefinedMenuItems()
  }

  func windowDidResignKey(_ notification: Notification) {
    needsUpdateFocus = editorViewController?.webView.isFirstResponder == true
    editorViewController?.cancelCompletion()
    editorViewController?.bridge.core.handleFocusLost()
  }

  func windowShouldZoom(_ window: NSWindow, toFrame newFrame: NSRect) -> Bool {
    // By default, zooming a window doesn't clear the tiling state,
    // this is different from moving or resizing the window.
    //
    // We manually clear the tiling state after a short delay to keep the behavior consistent.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
      guard let autosaveName = self?.windowFrameAutosaveName else {
        return
      }

      UserDefaults.resetTilingState(for: "NSWindow Frame \(autosaveName)")
    }

    return true
  }

  func windowDidResize(_ notification: Notification) {
    window?.saveFrame(usingName: windowFrameAutosaveName)
    editorViewController?.cancelCompletion()
  }

  // Capture tab state here, not in windowWillClose. By that point the window
  // is already removed from the tab group so tabbedWindows is nil.
  func windowShouldClose(_ sender: NSWindow) -> Bool {
    captureTabIndex(for: sender)
    return true
  }

  // Refresh titlebar appearance after fullscreen transitions,
  // when the final `.fullScreen` style mask bit is available.
  func windowDidEnterFullScreen(_ notification: Notification) {
    updateTitleBarAppearance()
  }

  func windowDidExitFullScreen(_ notification: Notification) {
    updateTitleBarAppearance()
  }
}

// MARK: - Private

private extension EditorWindowController {
  var editorViewController: EditorViewController? {
    contentViewController as? EditorViewController
  }

  func updateTitleBarAppearance() {
    (window as? EditorWindow)?.updateTitleBarAppearance()
    editorViewController?.updateWindowColors(.current)
  }

  func captureTabIndex(for window: NSWindow) {
    let document = editorViewController?.document
    let tabbedWindows = window.tabbedWindows
    let tabIndex = tabbedWindows?.firstIndex(of: window)
    let sibling = tabbedWindows?.first { $0 !== window }

    // tabbedWindows is nil for truly standalone windows, but a lone tab
    // broken out of a group reports tabbedWindows.count == 1. Treat both as standalone.
    let isStandalone = tabbedWindows == nil || tabbedWindows?.count == 1

    document?.lastTabIndex = tabIndex
    document?.lastWasStandalone = isStandalone
    document?.lastSiblingWindow = sibling
  }

  func saveWindowRect() {
  #if DEBUG
    guard ProcessInfo.processInfo.environment["DEBUG_TAKING_SCREENSHOTS"] != "YES" else {
      return
    }
  #endif

    // Editor view controllers are created without having a window (for pre-loading),
    // this is used for restoring the autosaved window frame.
    //
    // Unfortunately, we need to manually do the window cascading.
    //
    // Cascade from the frontmost existing EditorWindow's frame, not the new window's
    // autosaved frame, to ensure the visual offset is relative to what the user sees.
    let existingWindow = NSApp.orderedWindows.first {
      $0 is EditorWindow && $0 !== window
    }

    if let window, let sourceFrame = existingWindow?.frame {
      autosavedFrame = window.cascadeRect(from: sourceFrame)
    } else {
      autosavedFrame = window?.frame
    }
  }
}
