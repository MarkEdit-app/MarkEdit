//
//  AppDocumentController.swift
//  MarkEditMac
//
//  Created by cyan on 2024/10/14.
//

import AppKit

/**
 Subclass of `NSDocumentController` to allow customizations.

 NSDocumentController.shared will be an instance of `AppDocumentController` at runtime.
 */
final class AppDocumentController: NSDocumentController {
  override func beginOpenPanel() async -> [URL]? {
    if let defaultDirectory = AppRuntimeConfig.defaultOpenDirectory {
      setOpenPanelDirectory(defaultDirectory)
    }

    return await super.beginOpenPanel()
  }
}
