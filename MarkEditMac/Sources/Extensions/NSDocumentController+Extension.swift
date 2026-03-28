//
//  NSDocumentController+Extension.swift
//  MarkEditMac
//
//  Created by cyan on 10/14/24.
//

import AppKit
import MarkEditKit

extension NSDocumentController {
  var editorDocuments: [EditorDocument] {
    documents.compactMap { $0 as? EditorDocument }
  }

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
    UserDefaults.standard.set(directory, forKey: NSNavLastRootDirectory)
  }
}

// MARK: - Private

private extension NSDocumentController {
  var outdatedDocuments: [EditorDocument] {
    editorDocuments.filter { $0.isOutdated }
  }
}
