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

    openPanel.accessoryView = EditorSaveOptionsView.wrapper(for: .openPanel) { [weak openPanel] result in
      switch result {
      case .textEncoding(let value):
        Self.suggestedTextEncoding = value
      case .showHiddenFiles(let value):
        openPanel?.showsHiddenFiles = value
      default:
        Logger.assertFail("Invalid change: \(result)")
      }
    }

    Self.suggestedTextEncoding = nil
    openPanel.showsHiddenFiles = AppPreferences.General.showHiddenFiles

    return await super.beginOpenPanel(openPanel, forTypes: inTypes)
  }

  override func openDocument(
    withContentsOf url: URL,
    display displayDocument: Bool,
    completionHandler: @escaping (NSDocument?, Bool, (any Error)?) -> Void
  ) {
    if url.isBinaryFile {
      // Dead loop prevention
      if Bundle.main.isDefaultApp(toOpen: url) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
      } else {
        NSWorkspace.shared.open(url)
      }

      // Ignore the default opening logic
      completionHandler(nil, false, nil)
    } else {
      super.openDocument(
        withContentsOf: url,
        display: displayDocument,
        completionHandler: completionHandler
      )
    }
  }

  override func saveAllDocuments(_ sender: Any?) {
    // The default implementation doesn't work
    documents.forEach { $0.save(sender) }
  }
}
