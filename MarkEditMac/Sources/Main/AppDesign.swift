//
//  AppDesign.swift
//  MarkEditMac
//
//  Created by cyan on 6/12/25.
//

import AppKit
import AppKitExtensions

@MainActor
enum AppDesign {
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
    delegate.fileNewTabItem?.image = NSImage(systemSymbolName: Icons.interfaceWindowOnRectangle)
    delegate.fileReopenClosedTabItem?.image = delegate.fileNewTabItem?.image
  }
}
