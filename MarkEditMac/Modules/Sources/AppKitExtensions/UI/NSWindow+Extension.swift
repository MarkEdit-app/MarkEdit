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

  // What we want is an NSVisualEffectView child of an NSTitlebarView
  //
  // In macOS Tahoe, it can also be an NSTitlebarBackgroundView for the modern style
  var toolbarEffectView: NSView? {
    // [macOS 26] Revisit this later (#1281)
    for view in (toolbarContainerView?.subviews ?? []) {
      if view is NSVisualEffectView || view.className == "NSTitlebarBackgroundView" {
        return view
      }
    }

    return nil
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

  /// Change the frame size by a delta, treat the top-left corner as the anchor point.
  func resizeBy(_ delta: CGSize) {
    setFrameSize(CGSize(width: frame.width + delta.width, height: frame.height + delta.height))
  }

  /// Move the window to a web-style point, converting from top-left to bottom-left origin.
  func moveToWebPoint(_ point: CGPoint) {
    guard let screen else {
      return
    }

    setFrameOrigin(CGPoint(x: point.x, y: screen.frame.maxY - point.y - frame.height))
  }

  /// Move the window by a web-style delta, where positive y goes down.
  func moveByWebPoint(_ delta: CGPoint) {
    setFrameOrigin(CGPoint(x: frame.origin.x + delta.x, y: frame.origin.y - delta.y))
  }

  /// Move the window to the center of a screen, with an offset to look optically more centered.
  func centerOnScreen(_ screen: NSScreen? = .main, offset: Double = 20) {
    guard let visibleFrame = (screen ?? self.screen)?.visibleFrame else {
      return
    }

    setFrameOrigin(CGPoint(
      x: visibleFrame.minX + (visibleFrame.width - frame.size.width) * 0.5,
      y: visibleFrame.minY + (visibleFrame.height - frame.size.height) * 0.5 + offset
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

    // [macOS 26] Revisit this later (#1281)
    for window in NSApp.windows {
      // NSToolbarFullScreenWindow is used when the app is in full-screen mode
      if window.isMainWindow && window.className.hasPrefix("NSToolbarFullScreen") {
        return window
      }
    }

    return self
  }
}
