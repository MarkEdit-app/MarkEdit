//
//  EditorViewController+GotoLine.swift
//  MarkEditMac
//
//  Created by cyan on 1/17/23.
//

import AppKit
import AppKitControls
import MarkEditKit

extension EditorViewController {
  func showGotoLineWindow(_ sender: Any?) {
    guard let parentRect = view.window?.frame else {
      Logger.assertFail("Failed to retrieve window.frame to proceed")
      return
    }

    if completionContext.isPanelVisible {
      cancelCompletion()
    }

    let window = GotoLineWindow(
      relativeTo: parentRect,
      placeholder: Localized.Document.gotoLineLabel,
      accessibilityHelp: Localized.Document.gotoLineHelp,
      iconName: Icons.arrowUturnBackwardCircle
    ) { [weak self] lineNumber in
      self?.startWebViewEditing()
      self?.bridge.selection.gotoLine(lineNumber: lineNumber)
    }

    window.appearance = view.effectiveAppearance
    window.makeKeyAndOrderFront(sender)
  }
}
