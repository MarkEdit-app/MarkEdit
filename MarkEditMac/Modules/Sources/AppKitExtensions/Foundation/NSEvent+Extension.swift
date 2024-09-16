//
//  NSEvent+Extension.swift
//
//
//  Created by cyan on 2024/3/8.
//

import AppKit

public extension NSEvent {
  var deviceIndependentFlags: NSEvent.ModifierFlags {
    modifierFlags.intersection(.deviceIndependentFlagsMask)
  }
}

public extension UInt16 {
  static let kVK_ANSI_F: Self = 0x03
  static let kVK_ANSI_I: Self = 0x22
  static let kVK_Tab: Self = 0x30
  static let kVK_Delete: Self = 0x33
  static let kVK_Option: Self = 0x3A
  static let kVK_RightOption: Self = 0x3D
  static let kVK_DownArrow: Self = 0x7D
}
