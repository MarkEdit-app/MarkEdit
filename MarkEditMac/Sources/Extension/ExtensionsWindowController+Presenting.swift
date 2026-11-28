//
//  ExtensionsWindowController+Presenting.swift
//  MarkEditMac
//
//  Created by cyan on 11/28/26.
//

import AppKit

// MARK: - ExtensionsPresenting

extension ExtensionsWindowController: ExtensionsPresenting {
  func confirmUninstall(name: String) async -> Bool {
    let alert = NSAlert()
    alert.messageText = String(format: Localized.Extension.uninstallConfirmFormat, name)
    alert.informativeText = Localized.Extension.uninstallConfirmMessage
    alert.addButton(withTitle: Localized.Extension.uninstall).hasDestructiveAction = true
    alert.addButton(withTitle: Localized.General.cancel)
    return await presentSheetModal(alert) == .alertFirstButtonReturn
  }

  func reportFailure(_ error: Error) async {
    let alert = NSAlert()
    alert.messageText = Localized.Extension.failedTitle
    alert.informativeText = Localized.Extension.failureMessage(for: error)
    await presentSheetModal(alert)
  }
}

// MARK: - Private

private extension NSWindowController {
  @discardableResult
  func presentSheetModal(_ alert: NSAlert) async -> NSApplication.ModalResponse {
    guard let window, window.isVisible else {
      return alert.runModal()
    }

    return await alert.beginSheetModal(for: window)
  }
}
