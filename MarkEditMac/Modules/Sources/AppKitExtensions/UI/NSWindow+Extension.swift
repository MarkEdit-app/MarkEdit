//
//  NSWindow+Extension.swift
//
//  Created by cyan on 1/25/23.
//

import AppKit

public extension NSWindow {
  var toolbarContainerView: NSView? {
    toolbarRootView?.firstDescendant { (view: NSView) in
      view.className == "NSTitlebarView"
    }
  }

  var toolbarEffectView: NSVisualEffectView? {
    // What we want is an NSVisualEffectView child of an NSTitlebarView
    toolbarContainerView?.subviews.compactMap {
      $0 as? NSVisualEffectView
    }.first
  }

  var toolbarTitleView: NSView? {
    toolbarContainerView?.firstDescendant { (view: NSView) in
      view is NSTextField
    }
  }

  /// Change the frame size, treat the top-left corner as the anchor point.
  func setFrameSize(_ target: CGSize, display flag: Bool = false, animated: Bool = false) {
    let size = frameRect(forContentRect: CGRect(origin: .zero, size: target)).size
    let frame = CGRect(origin: frame.origin, size: size).offsetBy(dx: 0, dy: frame.height - size.height)
    setFrame(frame, display: flag, animate: animated)
  }

  /// Move to the center of the screen, the built-in .center() method doesn't work reliably.
  func moveToCenter() {
    guard let visibleSize = screen?.visibleFrame.size, let fullSize = screen?.frame.size else {
      return
    }

    setFrameOrigin(CGPoint(
      x: (visibleSize.width - frame.size.width) * 0.5,
      y: (visibleSize.height - frame.size.height) * 0.5 + fullSize.height - visibleSize.height
    ))
  }

  /// Get the cascade rect based on a rect.
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
    toolbarRootView?.firstDescendant { (button: NSPopUpButton) in
      button.menu?.identifier == menuIdentifier
    }
  }

  /// Returns the underlying view of an NSToolbarItem, your trustworthy friend.
  ///
  /// There's something called `NSToolbarItem.view`, it's non-nil only when we overwrite it.
  func toolbarButton(with itemIdentifier: NSToolbarItem.Identifier) -> NSButton? {
    toolbarRootView?.firstDescendant { (button: NSButton) in
      guard button.className == "NSToolbarButton" else {
        return false
      }

      guard let item = button.value(forKey: "item") as? NSToolbarItem else {
        return false
      }

      return item.itemIdentifier == itemIdentifier
    }
  }
}

// MARK: - Private

private extension NSWindow {
  var toolbarRootView: NSView? {
    var node = toolbarHostingWindow.contentView
    while node?.superview != nil {
      node = node?.superview
    }

    return node
  }

  var toolbarHostingWindow: NSWindow {
    guard NSApp.presentationOptions.contains(.fullScreen) else {
      return self
    }

    // NSToolbarFullScreenWindow is used when the app is in full-screen mode
    return NSApp.windows.first {
      $0.isKeyWindow && $0.className.hasPrefix("NSToolbarFullScreen")
    } ?? self
  }
}
