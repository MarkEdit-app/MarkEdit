//
//  AppHacks.swift
//  MarkEditMac
//
//  Created by cyan on 12/12/23.
//

import AppKit
import MarkEditKit

// [macOS 14] Performance regression, there's a good chance to hang at launch
extension NSObject {
  static var axbbmClass: AnyClass? {
    // Joined as: /System/Library/PrivateFrameworks/AccessibilityBundles.framework
    let path = [
      "",
      "System",
      "Library",
      "PrivateFrameworks",
      "AccessibilityBundles.framework",
    ].joined(separator: "/")

    guard let bundle = Bundle(path: path), bundle.load() else {
      Logger.assertFail("Failed to get the bundle")
      return nil
    }

    return NSClassFromString("AXBBundleManager")
  }

  /**
   Loading this bundle is extremely slow, move it to background thread with method swizzling.
   */
  static func swizzleAccessibilityBundles() {
    guard #available(macOS 14.0, *) else {
      return
    }

    guard let axbbmClass else {
      return Logger.assertFail("Failed to get the class to swizzle")
    }

    let originalSelector = sel_getUid("loadAXBundles")
    let swizzledSelector = #selector(swizzled_loadAXBundles)

    guard let originalMethod = class_getInstanceMethod(axbbmClass, originalSelector), let swizzledMethod = class_getInstanceMethod(Self.self, swizzledSelector) else {
      return Logger.assertFail("Failed to get the method to swizzle")
    }

    safelyExchangeMethods(
      type: axbbmClass,
      originalSelector: originalSelector,
      originalMethod: originalMethod,
      swizzledSelector: swizzledSelector,
      swizzledMethod: swizzledMethod
    )
  }
}

// MARK: - Private

private extension NSObject {
  @objc func swizzled_loadAXBundles() -> Bool {
    guard !NSWorkspace.shared.isVoiceOverEnabled else {
      return self.swizzled_loadAXBundles()
    }

    DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1) {
      _ = self.swizzled_loadAXBundles()
    }

    return true
  }
}
