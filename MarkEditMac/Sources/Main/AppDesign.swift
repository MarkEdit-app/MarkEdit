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
   Returns either an `NSVisualEffectView` or an `NSGlassEffectView`.

   `NSGlassEffectView` is used when `modernStyle` is available.
   */
  static var effectViewType: NSView.Type {
  #if BUILD_WITH_SDK_26_OR_LATER
    guard #available(macOS 26.0, *), modernStyle else {
      return NSVisualEffectView.self
    }

    return NSGlassEffectView.self
  #else
    return NSVisualEffectView.self
  #endif
  }
}
