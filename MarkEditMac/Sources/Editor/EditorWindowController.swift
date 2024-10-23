//
//  EditorWindowController.swift
//  MarkEditMac
//
//  Created by cyan on 12/12/22.
//

import AppKit

final class EditorWindowController: NSWindowController, NSWindowDelegate, @unchecked Sendable {
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
    for editor in EditorReusePool.shared.viewControllers() where editor !== editorViewController {
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

  func windowDidResize(_ notification: Notification) {
    window?.saveFrame(usingName: windowFrameAutosaveName)
    editorViewController?.cancelCompletion()
  }

  func windowWillClose(_ notification: Notification) {
    editorViewController?.clearEditor()
  }
}

// MARK: - Private

private extension EditorWindowController {
  var editorViewController: EditorViewController? {
    contentViewController as? EditorViewController
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
    if let window, NSApp.windows.filter({ $0 is EditorWindow }).count > 1 {
      autosavedFrame = window.cascadeRect(from: window.frame)
    } else {
      autosavedFrame = window?.frame
    }
  }
}
