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

    return true
  }

  /**
   Returns `true` to use a customized title bar for the editor.

   It will be enabled in macOS Tahoe and later.
   */
  static var modernTitleBar: Bool {
    modernStyle
  }

  /**
   Returns `true` to gradually add icons to the menu bar.

   It will be enabled in macOS Tahoe and later.
   */
  static var menuIconEvolution: Bool {
    modernStyle
  }

  static var dividerAlpha: Double {
    modernStyle ? 0.7 : 1.0
  }

  static var reduceTransparency: Bool {
    AppPreferences.Window.reduceTransparency || NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
  }

  static var reduceMotion: Bool {
    NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
  }

  /**
   Returns either an `NSGlassEffectView`, or an `NSVisualEffectView` as fallback.

   `NSGlassEffectView` is used when it is available and `modernStyle` is true.
   */
  static var modernEffectView: NSView.Type {
    guard #available(macOS 26.0, *), modernStyle else {
      return NSVisualEffectView.self
    }

    return NSGlassEffectView.self
  }
}
