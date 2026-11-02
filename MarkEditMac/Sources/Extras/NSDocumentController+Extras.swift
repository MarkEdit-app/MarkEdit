//
//  NSDocumentController+Extras.swift
//  MarkEditMac
//
//  Created by cyan on 10/14/24.
//

import AppKit
import MarkEditKit

extension NSDocumentController {
  static let swizzleInstallOpenRecentMenusOnce: () = {
    NSDocumentController.exchangeInstanceMethods(
      originalSelector: sel_getUid("_installOpenRecentMenus"),
      swizzledSelector: #selector(swizzled_installOpenRecentMenus)
    )
  }()

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
}

// MARK: - Private

private extension NSDocumentController {
  var outdatedDocuments: [EditorDocument] {
    editorDocuments.filter { $0.isOutdated }
  }

  @objc func swizzled_installOpenRecentMenus() {
    AppDeferredTasks.performWhenReady {
      self.swizzled_installOpenRecentMenus()
    }
  }
}
