//
//  EditorWindow.swift
//  MarkEditMac
//
//  Created by cyan on 1/12/23.
//

import AppKit

final class EditorWindow: NSWindow {
  var toolbarMode: ToolbarMode? {
    didSet {
      toolbarStyle = toolbarMode == .compact ? .unifiedCompact : .unified
      super.toolbar = toolbarMode == .hidden ? nil : cachedToolbar
    }
  }

  // swiftlint:disable:next discouraged_optional_boolean
  var reduceTransparency: Bool? {
    didSet {
      layoutIfNeeded()
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

  override func awakeFromNib() {
    super.awakeFromNib()
    toolbar = NSToolbar() // Required for multi-tab layout
    toolbarMode = AppPreferences.Window.toolbarMode
    tabbingMode = AppPreferences.Window.tabbingMode
    reduceTransparency = AppPreferences.Window.reduceTransparency
  }

  override func layoutIfNeeded() {
    super.layoutIfNeeded()

    // Slightly change the toolbar effect to match editor better
    if let view = toolbarEffectView {
      // Blend the color of contents behind the window
      view.blendingMode = .behindWindow
      view.isHidden = reduceTransparency == true

      // When self is the keyWindow, add a little transparency
      if isKeyWindow {
        view.alphaValue = effectiveAppearance.isDarkMode ? 0.3 : 0.7
      } else {
        view.alphaValue = 1.0
      }
    }
  }
}
