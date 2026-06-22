//
//  AppDesign.swift
//  MarkEditMac
//
//  Created by cyan on 6/12/25.
//

import AppKit
import FoundationModels

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

  /**
   Returns `true` to always enable `Show Writing Tools` in macOS Golden Gate.

   [macOS 27] Apple Bug: `Ask Siri` and `Show Writing Tools` are both missing.
   */
  static var forceWritingTools: Bool {
    guard #available(macOS 27.0, *) else {
      return false
    }

    // Don't use NSWritingToolsCoordinator.isWritingToolsAvailable here,
    // it returns `false` when "New Siri" is enabled.
    return SystemLanguageModel.default.isAvailable
  }

  static var dividerAlpha: Double {
    modernStyle ? 0.5 : 1.0
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

  static func migrateMainMenuIcons(delegate: AppDelegate) {
    guard Self.menuIconEvolution else {
      return
    }

    delegate.fileNewTabItem?.image = NSImage(
      systemSymbolName: Icons.interfaceWindowOnRectangle,
      accessibilityDescription: nil
    )

    delegate.fileReopenClosedTabItem?.image = delegate.fileNewTabItem?.image
  }
}
