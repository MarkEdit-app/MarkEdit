//
//  AppDocumentController.swift
//  MarkEditMac
//
//  Created by cyan on 10/14/24.
//

import AppKit
import MarkEditKit

/**
 Subclass of `NSDocumentController` to allow customizations.

 NSDocumentController.shared will be an instance of `AppDocumentController` at runtime.
 */
final class AppDocumentController: NSDocumentController {
  static var suggestedTextEncoding: EditorTextEncoding?
  static var suggestedFilename: String?

  override func beginOpenPanel(_ openPanel: NSOpenPanel, forTypes inTypes: [String]?) async -> Int {
    if let defaultDirectory = AppRuntimeConfig.defaultOpenDirectory {
      setOpenPanelDirectory(defaultDirectory)
    }

    openPanel.accessoryView = EditorSaveOptionsView.wrapper(for: .textEncoding) { result in
      if case .textEncoding(let value) = result {
        Self.suggestedTextEncoding = value
      }
    }

    Self.suggestedTextEncoding = nil
    return await super.beginOpenPanel(openPanel, forTypes: inTypes)
  }

  override func saveAllDocuments(_ sender: Any?) {
    // The default implementation doesn't work
    documents.forEach { $0.save(sender) }
  }
}
