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
  /**
   Loading this bundle is extremely slow, move it to background thread with method swizzling.
   */
  static let swizzleAccessibilityBundlesOnce: () = {
    guard let axbbmClass else {
      return Logger.assertFail("Failed to get the class to swizzle")
    }

    let originalSelector = sel_getUid("loadAXBundles")
    let swizzledSelector = #selector(swizzled_loadAXBundles)

    guard let originalMethod = class_getInstanceMethod(axbbmClass, originalSelector), let swizzledMethod = class_getInstanceMethod(NSObject.self, swizzledSelector) else {
      return Logger.assertFail("Failed to get the method to swizzle")
    }

    safelyExchangeMethods(
      type: axbbmClass,
      originalSelector: originalSelector,
      originalMethod: originalMethod,
      swizzledSelector: swizzledSelector,
      swizzledMethod: swizzledMethod
    )
  }()

  static let swizzleWebKitScrollerOnce: () = {
    guard #available(macOS 26.0, *), !AppRuntimeConfig.useClassicInterface else {
      return
    }

    guard let webKitScrollerClass else {
      return Logger.assertFail("Failed to get the class to swizzle")
    }

    let originalSelector = #selector(NSScreen.convertRectToBacking(_:))
    let swizzledSelector = #selector(swizzled_convertRectToBacking(_:))

    guard let originalMethod = class_getInstanceMethod(webKitScrollerClass, originalSelector), let swizzledMethod = class_getInstanceMethod(NSObject.self, swizzledSelector) else {
      return Logger.assertFail("Failed to get the method to swizzle")
    }

    safelyExchangeMethods(
      type: webKitScrollerClass,
      originalSelector: originalSelector,
      originalMethod: originalMethod,
      swizzledSelector: swizzledSelector,
      swizzledMethod: swizzledMethod
    )
  }()
}

// MARK: - Private

private extension NSObject {
  enum States {
    static var loaded = false
  }

  @objc func swizzled_loadAXBundles() -> Bool {
    defer {
      States.loaded = true
    }

    guard !States.loaded else {
      return false
    }

    guard !NSWorkspace.shared.isVoiceOverEnabled else {
      return self.swizzled_loadAXBundles()
    }

    DispatchQueue.global(qos: .userInitiated).async {
      _ = self.swizzled_loadAXBundles()
    }

    return true
  }

  @objc func swizzled_convertRectToBacking(_ rect: CGRect) -> CGRect {
    var rect = self.swizzled_convertRectToBacking(rect)
    rect.size.height = max(0, rect.height - 15)

    return rect
  }
}
