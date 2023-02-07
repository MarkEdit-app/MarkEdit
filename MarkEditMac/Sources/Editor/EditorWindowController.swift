//
//  EditorWindowController.swift
//  MarkEditMac
//
//  Created by cyan on 12/12/22.

import AppKit

final class EditorWindowController: NSWindowController, NSWindowDelegate {
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    shouldCascadeWindows = true
  }

  override func windowDidLoad() {
    super.windowDidLoad()
    window?.minSize = CGSize(width: 240, height: 0)
    window?.backgroundColor = .controlBackgroundColor
  }

  func windowDidBecomeMain(_ notification: Notification) {
    NSApplication.shared.closeOpenPanels()
  }

  func windowWillClose(_ notification: Notification) {
    (contentViewController as? EditorViewController)?.clearEditor()
  }
}
