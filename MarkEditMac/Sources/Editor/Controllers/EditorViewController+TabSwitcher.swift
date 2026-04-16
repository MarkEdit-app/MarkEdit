//
//  EditorViewController+TabSwitcher.swift
//  MarkEditMac
//
//  Created by lamchau on 4/16/26.
//

import AppKit
import AppKitControls
import MarkEditKit

extension EditorViewController {
  @IBAction func showTabSwitcher(_ sender: Any?) {
    guard !(NSApp.keyWindow is TabSwitcherWindow) else { return }

    guard let parentRect = view.window?.frame else {
      Logger.assertFail("Failed to retrieve window.frame to proceed")
      return
    }

    let documents = NSDocumentController.shared.editorDocuments

    guard !documents.isEmpty else {
      return
    }

    if completionContext.isPanelVisible {
      cancelCompletion()
    }

    let currentDocument = view.window?.windowController?.document as? EditorDocument
    var initialSelection = 0

    let items = documents.enumerated().map { index, document in
      if document === currentDocument {
        initialSelection = index
      }

      let title = document.displayName ?? ""
      let subtitle = (document.fileURL?.deletingLastPathComponent().path as NSString?)?.abbreviatingWithTildeInPath ?? ""

      return TabSwitcherItem(title: title, subtitle: subtitle) { [weak document] in
        guard let window = document?.windowControllers.first?.window else {
          return
        }

        window.makeKeyAndOrderFront(nil)

        if let tabGroup = window.tabGroup {
          tabGroup.selectedWindow = window
        }
      }
    }

    let window = TabSwitcherWindow(
      effectViewType: AppDesign.modernEffectView,
      relativeTo: parentRect,
      placeholder: Localized.Document.tabSwitcherLabel,
      accessibilityHelp: Localized.Document.tabSwitcherHelp,
      emptyMessage: Localized.Document.tabSwitcherEmpty,
      items: items,
      initialSelection: initialSelection
    )

    window.appearance = view.effectiveAppearance
    window.makeKeyAndOrderFront(sender)
  }
}
