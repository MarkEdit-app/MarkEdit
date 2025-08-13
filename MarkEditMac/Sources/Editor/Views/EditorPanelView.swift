//
//  EditorPanelView.swift
//  MarkEditMac
//
//  Created by cyan on 12/27/22.
//

import AppKit
import AppKitControls

class EditorPanelView: NSView, BackgroundTheming {
  init() {
    super.init(frame: .zero)
    wantsLayer = true
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func resetCursorRects() {
    addCursorRect(bounds, cursor: .arrow)
  }
}
