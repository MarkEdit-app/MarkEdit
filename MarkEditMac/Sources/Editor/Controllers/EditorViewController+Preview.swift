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
