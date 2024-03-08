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
  static let kVK_ANSI_F: UInt16 = 0x03
  static let kVK_Tab: UInt16 = 0x30
  static let kVK_Delete: UInt16 = 0x33
  static let kVK_Option: UInt16 = 0x3A
}
