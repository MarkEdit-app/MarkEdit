//
//  EditorWindow.swift
//  MarkEditMac
//
//  Created by cyan on 1/12/23.
//

import AppKit
import MarkEditKit

final class EditorWindow: NSWindow {
  /// Forces `.preferred` tabbing for an on-demand window (e.g. "New Tab"),
  /// without mutating the persisted `AppPreferences.Window.tabbingMode`.
  @MainActor static var forcedTabbing = false

  var toolbarMode: ToolbarMode? {
    didSet {
      toolbarStyle = toolbarMode == .compact ? .unifiedCompact : .unified
      super.toolbar = toolbarMode == .hidden ? nil : cachedToolbar
      updateTitleBarAppearance()
    }
  }

  var reduceTransparency: Bool? {
    didSet {
      updateTitleBarAppearance()
    }
  }

  var prefersTintedToolbar: Bool = false {
    didSet {
      updateTitleBarAppearance()
    }
  }

  override var toolbar: NSToolbar? {
    get {
      super.toolbar
    }
    set {
      cachedToolbar = newValue
      super.toolbar = toolbarMode == .hidden ? nil : newValue
    }
  }

  private var cachedToolbar: NSToolbar?
  private weak var cachedTitlebarBackgroundView: NSView?
  private weak var cachedTitlebarDecorationView: NSView?

  override func awakeFromNib() {
    super.awakeFromNib()
    toolbar = NSToolbar() // Required for multi-tab layout
    toolbarMode = AppPreferences.Window.toolbarMode
    tabbingMode = Self.forcedTabbing ? .preferred : AppPreferences.Window.tabbingMode
    reduceTransparency = AppDesign.reduceTransparency
  }

  override func layoutIfNeeded() {
    super.layoutIfNeeded()
    updateTitleBarAppearance(clearCaches: false)
  }

  /// Applies all custom title-bar tweaks derived from current state:
  /// `(isFullscreen, toolbarMode, reduceTransparency, prefersTintedToolbar)`.
  /// Safe to call repeatedly; also runs implicitly after each layout pass.
  func updateTitleBarAppearance(clearCaches: Bool = true) {
    if clearCaches {
      cachedTitlebarBackgroundView = nil
      cachedTitlebarDecorationView = nil
    }

    // The titlebar background view also backs the auto-hiding titlebar overlay in
    // fullscreen. When the toolbar is hidden, nothing else backs it, so keep
    // the effect view visible and fully opaque in that specific case to avoid
    // a transparent overlay.
    if cachedTitlebarBackgroundView == nil {
      cachedTitlebarBackgroundView = titlebarBackgroundView
    }

    if let view = cachedTitlebarBackgroundView {
      let needsOverlay = styleMask.contains(.fullScreen) && toolbarMode == .hidden
      view.alphaValue = needsOverlay ? 1 : (prefersTintedToolbar ? 0.3 : 0.7)
      view.isHidden = !needsOverlay

      // Blend the color of contents behind the window
      (view as? NSVisualEffectView)?.blendingMode = .behindWindow
    } else {
      Logger.assertFail("Missing cachedTitlebarBackgroundView")
    }

    if cachedTitlebarDecorationView == nil {
      cachedTitlebarDecorationView = titlebarDecorationView
    }

    // Disable the separator instead of using `titlebarAppearsTransparent`,
    // which breaks "Merge All Windows".
    if let view = cachedTitlebarDecorationView {
      let selector = sel_getUid("setDrawsBottomSeparator:")
      if view.responds(to: selector) {
        unsafeBitCast(
          view.method(for: selector),
          to: (@convention(c) (NSView, Selector, Bool) -> Void).self
        )(view, selector, false)
      } else {
        Logger.assertFail("Missing setDrawsBottomSeparator: in _NSTitlebarDecorationView")
        view.isHidden = true
      }
    } else {
      Logger.assertFail("Missing cachedTitlebarDecorationView")
    }
  }
}
