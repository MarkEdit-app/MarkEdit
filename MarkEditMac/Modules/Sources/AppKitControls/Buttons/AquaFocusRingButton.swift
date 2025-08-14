//
//  AquaFocusRingButton.swift
//
//  Created by cyan on 8/13/25.
//

import AppKit

/**
 Custom drawing to make the focus ring stronger.

 This is needed for legacy OS only.
 */
public final class AquaFocusRingButton: NSButton {
  override init(frame: CGRect) {
    super.init(frame: frame)
    focusRingType = .exterior
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func drawFocusRingMask() {
    // [macOS 26] Change this to 26.0
    if #available(macOS 16.0, *) {
      return super.drawFocusRingMask()
    }

    var frame = bounds
    frame.size.height -= 1 // The bezel shadow height
    NSBezierPath(roundedRect: frame, radius: 5).fill()
  }
}
