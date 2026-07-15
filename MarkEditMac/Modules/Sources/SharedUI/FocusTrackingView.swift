//
//  FocusTrackingView.swift
//
//  Created by cyan on 1/7/23.
//

import AppKit

/**
 Tracks the focus rect to help us present popovers.
 */
public final class FocusTrackingView: NSView {
  override public func hitTest(_ point: NSPoint) -> NSView? {
    nil
  }

  override public func isAccessibilityHidden() -> Bool {
    true
  }
}
