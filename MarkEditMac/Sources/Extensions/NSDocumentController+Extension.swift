//
//  NSDocumentController+Extension.swift
//  MarkEditMac
//
//  Created by cyan on 10/14/24.
//

import AppKit
import MarkEditKit

extension NSDocumentController {
  var hasDirtyDocuments: Bool {
    let documents = NSDocumentController.shared.documents.compactMap {
      $0 as? EditorDocument
    }

    return documents.contains { $0.isContentDirty }
  }

  /**
   Force the override of the last root directory for NSOpenPanel and NSSavePanel.
   */
  func setOpenPanelDirectory(_ directory: String) {
    UserDefaults.standard.setValue(directory, forKey: NSNavLastRootDirectory)
  }
}
