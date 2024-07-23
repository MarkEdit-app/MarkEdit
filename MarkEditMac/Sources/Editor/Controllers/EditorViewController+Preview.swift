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
    let popover = NSPopover()
    popover.behavior = .transient
    popover.contentViewController = Previewer(code: code, type: type)
    presentPopover(popover, rect: rect)
  }
}

// MARK: - Private

private extension EditorViewController {
  func presentPopover(_ popover: NSPopover, rect: CGRect) {
    if focusTrackingView.superview == nil {
      webView.addSubview(focusTrackingView)
    }

    // The origin has to be inside the viewport, and the size cannot be zero
    focusTrackingView.frame = CGRect(
      x: max(0, rect.minX),
      y: max(0, rect.minY),
      width: max(1, rect.width),
      height: max(1, rect.height)
    )

    previewPopover = popover
    popover.show(relativeTo: rect, of: focusTrackingView, preferredEdge: .maxX)
  }
}
