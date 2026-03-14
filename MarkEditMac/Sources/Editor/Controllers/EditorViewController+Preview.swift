//
//  EditorViewController+Preview.swift
//  MarkEditMac
//
//  Created by cyan on 1/7/23.
//

import AppKit
import Previewer
import MarkEditKit

extension EditorViewController {
  /// Preview the entire document as a Mermaid diagram; intended for .mmd files.
  func previewDiagram(sender: NSToolbarItem) {
    Task {
      guard let text = await editorText, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        return
      }

      if removePresentedPopovers(contentClass: Previewer.self) {
        return
      }

      let previewer = Previewer(code: text, type: .mermaid)

      // Anchor the popover to the toolbar button if available; otherwise the top of the webView.
      if let anchor = sender.view {
        present(previewer, asPopoverRelativeTo: anchor.bounds, of: anchor, preferredEdge: .minY, behavior: .transient)
      } else {
        presentAsPopover(contentViewController: previewer, rect: CGRect(x: 0, y: webView.bounds.height, width: 1, height: 1))
      }
    }
  }

  func showPreview(code: String, type: PreviewType, rect: CGRect) {
    if removePresentedPopovers(contentClass: Previewer.self) {
      return
    }

    let previewer = Previewer(code: code, type: type)
    presentAsPopover(contentViewController: previewer, rect: rect)
  }
}

// MARK: - Private

private extension EditorViewController {
  func presentAsPopover(contentViewController: Previewer, rect: CGRect) {
    if focusTrackingView.superview == nil {
      webView.addSubview(focusTrackingView)
    }

    // The origin has to be inside the viewport
    focusTrackingView.frame = CGRect(
      x: max(0, rect.minX),
      y: max(0, rect.minY),
      width: rect.width,
      height: rect.height
    )

    present(
      contentViewController,
      asPopoverRelativeTo: focusTrackingView.bounds,
      of: focusTrackingView,
      preferredEdge: .maxX,
      behavior: .transient
    )
  }
}
