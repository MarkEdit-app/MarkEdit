//
//  NSViewController+Extension.swift
//
//  Created by cyan on 1/8/23.
//

import AppKit

@MainActor
public protocol UISheetModal {
  func runModal() -> NSApplication.ModalResponse
  func beginSheetModal(for sheetWindow: NSWindow) async -> NSApplication.ModalResponse
}

extension NSAlert: UISheetModal {}
extension NSSavePanel: UISheetModal {}

public extension NSViewController {
  var popover: NSPopover? {
    view.window?.value(forKey: "_popover") as? NSPopover
  }

  @discardableResult
  func presentSheetModal(_ sheetModal: UISheetModal) async -> NSApplication.ModalResponse {
    guard let window = view.window else {
      return sheetModal.runModal()
    }

    return await sheetModal.beginSheetModal(for: window)
  }
}
