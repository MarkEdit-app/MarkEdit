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

public extension NSEvent.ModifierFlags {
  private static let mapping: [String: NSEvent.ModifierFlags] = [
    "Shift": .shift,
    "Control": .control,
    "Option": .option,
    "Command": .command,
  ]

  init(stringValues: [String]) {
    var modifiers: NSEvent.ModifierFlags = []
    stringValues.forEach {
      if let modifier = Self.mapping[$0] {
        modifiers.insert(modifier)
      }
    }

    self = modifiers
  }
}

public extension UInt16 {
  static let kVK_ANSI_F: Self = 0x03
  static let kVK_ANSI_I: Self = 0x22
  static let kVK_Tab: Self = 0x30
  static let kVK_Delete: Self = 0x33
  static let kVK_Option: Self = 0x3A
  static let kVK_RightOption: Self = 0x3D
  static let kVK_LeftArrow: Self = 0x7B
  static let kVK_RightArrow: Self = 0x7C
  static let kVK_DownArrow: Self = 0x7D
}
