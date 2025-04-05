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
    !dirtyDocuments.isEmpty
  }

  func saveDirtyDocuments() async {
    await withTaskGroup(of: Void.self) { group in
      for document in dirtyDocuments {
        group.addTask { @MainActor in
          await withCheckedContinuation { continuation in
            document.saveContent(nil) {
              continuation.resume()
            }
          }
        }
      }
    }

    // It takes sometime to actually save the document
    await withCheckedContinuation { continuation in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        continuation.resume()
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
  var dirtyDocuments: [EditorDocument] {
    NSDocumentController.shared.documents.compactMap {
      guard let document = $0 as? EditorDocument, document.isContentDirty else {
        return nil
      }

      return document
    }
  }
}
