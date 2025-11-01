//
//  AppDesign.swift
//  MarkEditMac
//
//  Created by cyan on 6/12/25.
//

import AppKit

@MainActor
enum AppDesign {
  /**
    Returns `true` to adopt the new design language in macOS Tahoe.
   */
  static var modernStyle: Bool {
    guard #available(macOS 26.0, *) else {
      return false
    }

    return !AppRuntimeConfig.useClassicInterface
  }

  /**
   Returns `true` to use a customized title bar for the editor.

   It will be enabled as long as macOS Tahoe runs.
   */
  static var modernTitleBar: Bool {
    isMacOSTahoe
  }

  /**
   Returns `true` to gradually add icons to the menu bar.

   It will be enabled as long as macOS Tahoe runs.
   */
  static var menuIconEvolution: Bool {
    isMacOSTahoe
  }

  static var reduceTransparency: Bool {
    AppPreferences.Window.reduceTransparency || NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
  }

  /**
   Returns either an `NSGlassEffectView`, or an `NSVisualEffectView` as fallback.

   `NSGlassEffectView` is used when it is available and `modernStyle` is true.
   */
  static var modernEffectView: NSView.Type {
    guard #available(macOS 26.0, *), modernStyle && AppRuntimeConfig.visualEffectType == .glass else {
      return NSVisualEffectView.self
    }

    return NSGlassEffectView.self
  }
}

// MARK: - Private

private extension AppDesign {
  static var isMacOSTahoe: Bool {
    guard #available(macOS 26.0, *) else {
      return false
    }

    return true
  }
}
