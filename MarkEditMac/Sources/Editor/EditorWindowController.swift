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

  func windowDidBecomeMain(_ notification: Notification) {
    NSApplication.shared.closeOpenPanels()
  }

  func windowDidResize(_ notification: Notification) {
    window?.saveFrame(usingName: windowFrameAutosaveName)
  }

  func windowWillClose(_ notification: Notification) {
    (contentViewController as? EditorViewController)?.clearEditor()
  }
}
