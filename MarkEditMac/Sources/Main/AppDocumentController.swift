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

    // Create an observer to sync showHiddenFiles between the panel and the view
    let showHiddenFilesObserver = ShowHiddenFilesObserver(initialValue: AppPreferences.General.showHiddenFiles)
    
    // Set up KVO to observe changes from keyboard shortcut (Cmd+Shift+.)
    let observation = openPanel.observe(\.showsHiddenFiles, options: [.new]) { [weak showHiddenFilesObserver] _, change in
      guard let newValue = change.newValue else { return }
      DispatchQueue.main.async {
        showHiddenFilesObserver?.value = newValue
        AppPreferences.General.showHiddenFiles = newValue
      }
    }
    
    openPanel.accessoryView = EditorSaveOptionsView.wrapper(for: .openPanel, showHiddenFilesObserver: showHiddenFilesObserver) { [weak openPanel] result in
      switch result {
      case .textEncoding(let value):
        Self.suggestedTextEncoding = value
      case .showHiddenFiles(let value):
        openPanel?.showsHiddenFiles = value
        AppPreferences.General.showHiddenFiles = value
      default:
        Logger.assertFail("Invalid change: \(result)")
      }
    }

    Self.suggestedTextEncoding = nil
    openPanel.showsHiddenFiles = AppPreferences.General.showHiddenFiles

    let result = await super.beginOpenPanel(openPanel, forTypes: inTypes)
    
    // Keep the observation alive until this point (after panel is dismissed)
    // The observation is automatically cleaned up when it goes out of scope
    withExtendedLifetime(observation) {}
    
    return result
  }

  override func saveAllDocuments(_ sender: Any?) {
    // The default implementation doesn't work
    documents.forEach { $0.save(sender) }
  }
}
