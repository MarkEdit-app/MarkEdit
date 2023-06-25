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

    previewingPopover = popover
    presentPopover(popover, rect: rect)
  }
}
