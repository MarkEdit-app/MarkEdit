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
    0.7
  }

  static var reduceTransparency: Bool {
    AppPreferences.Window.reduceTransparency || NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
  }

  static var reduceMotion: Bool {
    NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
  }

  static var modernEffectView: NSView.Type {
    NSGlassEffectView.self
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
