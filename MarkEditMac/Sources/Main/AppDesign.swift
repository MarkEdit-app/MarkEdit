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
    return false
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
