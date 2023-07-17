//
//  EditorWindowController.swift
//  MarkEditMac
//
//  Created by cyan on 12/12/22.

import AppKit

final class EditorWindowController: NSWindowController, NSWindowDelegate {
  var autosavedFrame: CGRect?

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

  func windowDidResize(_ notification: Notification) {
    window?.saveFrame(usingName: windowFrameAutosaveName)
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
