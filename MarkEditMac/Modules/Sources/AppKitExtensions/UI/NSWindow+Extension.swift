//
//  NSWindow+Extension.swift
//
//  Created by cyan on 1/25/23.
//

import AppKit
import MarkEditKit

public extension NSWindow {
  var toolbarContainerView: NSView? {
    toolbarEffectView?.superview
  }

  var toolbarEffectView: NSVisualEffectView? {
    var result: NSVisualEffectView?
    rootView?.enumerateChildren { (view: NSVisualEffectView) in
      // Blindly consider a full-width NSVisualEffectView the toolbar,
      // a more accurate way would be relying on NSThemeFrame, which is private.
      if abs(view.frame.width - frame.width) < .ulpOfOne {
        result = view
      }
    }

    assert(result != nil, "Failed to find NSVisualEffectView in toolbar")
    return result
  }

  /// Change the frame size, treat the top-left corner as the anchor point
  func setFrameSize(_ target: CGSize, display flag: Bool = false, animated: Bool = false) {
    let size = frameRect(forContentRect: CGRect(origin: .zero, size: target)).size
    let frame = CGRect(origin: frame.origin, size: size).offsetBy(dx: 0, dy: frame.height - size.height)
    setFrame(frame, display: flag, animate: animated)
  }

  /// Move to the center of the screen, the built-in .center() method doesn't work reliably
  func moveToCenter() {
    guard let visibleSize = screen?.visibleFrame.size, let fullSize = screen?.frame.size else {
      return
    }

    setFrameOrigin(CGPoint(
      x: (visibleSize.width - frame.size.width) * 0.5,
      y: (visibleSize.height - frame.size.height) * 0.5 + fullSize.height - visibleSize.height
    ))
  }

  /// Get the cascade rect based on a rect
  func cascadeRect(from rect: CGRect) -> CGRect {
    let origin = cascadeTopLeft(from: CGPoint(
      x: rect.origin.x,
      y: rect.origin.y + rect.height
    ))

    return CGRect(origin: CGPoint(x: origin.x, y: origin.y - rect.height), size: rect.size)
  }

  /// Get the popUp button associated with an NSMenu.
  ///
  /// There's no public API to programmatically show the menu assigned to an NSToolbarItem.
  func popUpButton(with menuIdentifier: NSUserInterfaceItemIdentifier) -> NSPopUpButton? {
    guard let view = contentView?.superview else {
      Logger.log(.error, "Failed to obtain superview from contentView of: \(self)")
      return nil
    }

    var result: NSPopUpButton?
    view.enumerateChildren { (button: NSPopUpButton) in
      if button.menu?.identifier == menuIdentifier {
        result = button
      }
    }

    Logger.log(.error, "Failed to find popUp button of menu: \(menuIdentifier)")
    return result
  }
}

// MARK: - Private

private extension NSWindow {
  var rootView: NSView? {
    var node = contentView
    while node?.superview != nil {
      node = node?.superview
    }

    return node
  }
}
