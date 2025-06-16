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
  #if BUILD_WITH_SDK_26_OR_LATER
    guard #available(macOS 26.0, *) else {
      return false
    }

    return !AppRuntimeConfig.useClassicInterface
  #else
    // macOS Tahoe version number is 16.0 if the SDK is old
    guard #available(macOS 16.0, *) else {
      return false
    }

    // defaults write app.cyan.markedit com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck -bool true
    return UserDefaults.standard.bool(forKey: "com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck")
  #endif
  }

  /**
   Returns `true` to use a customized title bar for the editor.

   This doesn't require the new SDK and cannot be configured.
   */
  static var modernTitleBar: Bool {
    // [macOS 26] Change this to 26.0
    guard #available(macOS 16.0, *) else {
      return false
    }

    return true
  }

  /**
   Returns either an `NSGlassEffectView`, or an `NSVisualEffectView` as fallback.

   `NSGlassEffectView` is used when it is available.
   */
  static var modernEffectView: NSView.Type {
    // [macOS 26] Change this to 26.0
    guard #available(macOS 16.0, *) else {
      return NSVisualEffectView.self
    }

  #if BUILD_WITH_SDK_26_OR_LATER
    return NSGlassEffectView.self
  #else
    // Reflect a glass effect view when it's available
    return (NSClassFromString("NSGlassEffectView") as? NSView.Type) ?? NSVisualEffectView.self
  #endif
  }

  static var defaultEffectView: NSView.Type {
    modernStyle ? modernEffectView : NSVisualEffectView.self
  }
}
