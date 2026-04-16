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

  var reduceTransparency: Bool? {
    didSet {
      layoutIfNeeded()
    }
  }

  var prefersTintedToolbar: Bool = false {
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
    titlebarAppearsTransparent = AppDesign.modernTitleBar
    reduceTransparency = AppDesign.reduceTransparency

    if AppPreferences.Window.alwaysShowTabBar {
      DispatchQueue.main.async { [weak self] in
        self?.setTabBarVisible(true)
      }
    }
  }

  func setTabBarVisible(_ visible: Bool) {
    guard let tabGroup = tabGroup else { return }
    if tabGroup.isTabBarVisible != visible {
      toggleTabBar(nil)
    }
  }

  override func layoutIfNeeded() {
    super.layoutIfNeeded()

    // Slightly change the toolbar effect to match editor better
    if let view = toolbarEffectView {
      view.alphaValue = prefersTintedToolbar ? 0.3 : 0.7
      view.isHidden = reduceTransparency == true || AppDesign.modernTitleBar

      // Blend the color of contents behind the window
      (view as? NSVisualEffectView)?.blendingMode = .behindWindow
    }
  }
}
