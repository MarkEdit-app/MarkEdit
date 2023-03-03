//
//  NSObject+Extension.swift
//
//  Created by cyan on 2/28/23.
//

import Foundation

public extension NSObject {
  /// Exchange two instance methods during runtime.
  static func exchangeInstanceMethods(originalSelector: Selector, swizzledSelector: Selector) {
    let type = Self.self

    guard let originalMethod = class_getInstanceMethod(type, originalSelector) else {
      Logger.assertFail("Failed to swizzle: \(type), missing original method")
      return
    }

    guard let swizzledMethod = class_getInstanceMethod(type, swizzledSelector) else {
      Logger.assertFail("Failed to swizzle: \(type), missing swizzled method")
      return
    }

    if class_addMethod(type, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod)) {
      class_replaceMethod(type, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
    } else {
      method_exchangeImplementations(originalMethod, swizzledMethod)
    }
  }
}
