//
//  NSObject+Extension.swift
//
//  Created by cyan on 10/25/24.
//

import Foundation

public extension NSObject {
  /**
   Private accessibility bundle class, used to work around performance issues.
   */
  static var axbbmClass: AnyClass? {
    // Joined as: /System/Library/PrivateFrameworks/AccessibilityBundles.framework
    let path = [
      "",
      "System",
      "Library",
      "PrivateFrameworks",
      "AccessibilityBundles.framework",
    ].joined(separator: "/")

    Bundle(path: path)?.load()
    return NSClassFromString("AXBBundleManager")
  }
}
