//
//  NSDocumentController+Extension.swift
//  MarkEditMac
//
//  Created by cyan on 10/14/24.
//

import AppKit
import MarkEditKit

extension NSDocumentController {
  var hasOutdatedDocuments: Bool {
    !outdatedDocuments.isEmpty
  }

  func saveOutdatedDocuments(userInitiated: Bool = false) async {
    await withTaskGroup(of: Void.self) { group in
      for document in outdatedDocuments {
        group.addTask {
          await document.waitUntilSaveCompleted(userInitiated: userInitiated)
        }
      }
    }
  }

  /**
   Force the override of the last root directory for NSOpenPanel and NSSavePanel.
   */
  func setOpenPanelDirectory(_ directory: String) {
    UserDefaults.standard.setValue(directory, forKey: NSNavLastRootDirectory)
  }
}

// MARK: - Private

private extension NSDocumentController {
  var outdatedDocuments: [EditorDocument] {
    NSDocumentController.shared.documents.compactMap {
      guard let document = $0 as? EditorDocument, document.isOutdated else {
        return nil
      }

      return document
    }
  }
}
