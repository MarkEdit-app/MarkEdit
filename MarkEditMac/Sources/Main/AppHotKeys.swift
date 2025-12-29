//
//  AppHotKeys.swift
//  MarkEditMac
//
//  Created by cyan on 8/7/24.
//

import Foundation
import Carbon.HIToolbox
import MarkEditKit

@MainActor
enum AppHotKeys {
  struct Modifiers: OptionSet {
    let rawValue: Int
    static let shift = Self(rawValue: shiftKey)
    static let control = Self(rawValue: controlKey)
    static let option = Self(rawValue: optionKey)
    static let command = Self(rawValue: cmdKey)

    init(rawValue: Int) {
      self.rawValue = rawValue
    }

    fileprivate init(stringValues: [String]) {
      let mapping = [
        "Shift": shiftKey,
        "Control": controlKey,
        "Option": optionKey,
        "Command": cmdKey,
      ]

      self.rawValue = ({
        var modifiers: Self = []
        stringValues.forEach {
          if let rawValue = mapping[$0] {
            modifiers.insert(Self(rawValue: rawValue))
          } else {
            Logger.log(.error, "Invalid modifier was found: \($0)")
          }
        }

        return modifiers.rawValue
      })()
    }
  }

  static func register(keyEquivalent: String, modifiers: [String], handler: @escaping () -> Void) {
    guard let keyCode = virtualKeyCodes[keyEquivalent] else {
      return Logger.log(.error, "Failed to find keyCode for: \(keyEquivalent)")
    }

    register(keyCode: keyCode, modifiers: .init(stringValues: modifiers), handler: handler)
  }

  static func register(keyCode: UInt32, modifiers: Modifiers, handler: @escaping () -> Void) {
    var eventHotKey: EventHotKeyRef?
    let registerError = RegisterEventHotKey(
      keyCode,
      UInt32(modifiers.rawValue),
      EventHotKeyID(signature: hotKeySignature, id: hotKeyID),
      GetEventDispatcherTarget(),
      0,
      &eventHotKey
    )

    if registerError != noErr {
      Logger.log(.error, "Failed to register hotKey: \(keyCode), \(modifiers)")
    }

    installEventHandler()
    mappedHandlers[hotKeyID] = handler
    hotKeyID += 1
  }
}

// MARK: - Private

private extension AppHotKeys {
  static func installEventHandler() {
    guard eventHandler == nil, let target = GetEventDispatcherTarget() else {
      return
    }

    let eventTypes = [
      EventTypeSpec(
        eventClass: OSType(kEventClassKeyboard),
        eventKind: UInt32(kEventHotKeyPressed)
      ),
    ]

    let installError = InstallEventHandler(
      target,
      { _, event, _ in handleEvent(event) },
      eventTypes.count,
      eventTypes,
      nil,
      &eventHandler
    )

    if installError != noErr {
      Logger.log(.error, "Failed to install event handler for hotKey")
    }
  }
}

@MainActor private var eventHandler: EventHandlerRef?
@MainActor private var hotKeyID = UInt32(0)
@MainActor private var mappedHandlers = [UInt32: () -> Void]()

@MainActor
private func handleEvent(_ event: EventRef?) -> OSStatus {
  guard let event, Int(GetEventKind(event)) == kEventHotKeyPressed else {
    Logger.log(.error, "Event \(String(describing: event)) not handled")
    return OSStatus(eventNotHandledErr)
  }

  var eventHotKeyId = EventHotKeyID()
  let error = GetEventParameter(
    event,
    UInt32(kEventParamDirectObject),
    UInt32(typeEventHotKeyID),
    nil,
    MemoryLayout<EventHotKeyID>.size,
    nil,
    &eventHotKeyId
  )

  guard error == noErr, eventHotKeyId.signature == hotKeySignature else {
    Logger.log(.error, "Failed to validate the event")
    return error
  }

  guard let handler = mappedHandlers[eventHotKeyId.id] else {
    Logger.log(.error, "Failed to get the event handler")
    return OSStatus(eventNotHandledErr)
  }

  handler()
  return noErr
}

// OSType of "MEHK" (MarkEdit HotKey)
private let hotKeySignature: UInt32 = 1296386123

// https://gist.github.com/eegrok/949034
private let virtualKeyCodes: [String: UInt32] = [
  "A": 0x00,
  "B": 0x0B,
  "C": 0x08,
  "D": 0x02,
  "E": 0x0E,
  "F": 0x03,
  "G": 0x05,
  "H": 0x04,
  "I": 0x22,
  "J": 0x26,
  "K": 0x28,
  "L": 0x25,
  "M": 0x2E,
  "N": 0x2D,
  "O": 0x1F,
  "P": 0x23,
  "Q": 0x0C,
  "R": 0x0F,
  "S": 0x01,
  "T": 0x11,
  "U": 0x20,
  "V": 0x09,
  "W": 0x0D,
  "X": 0x07,
  "Y": 0x10,
  "Z": 0x06,

  "1": 0x12,
  "2": 0x13,
  "3": 0x14,
  "4": 0x15,
  "5": 0x17,
  "6": 0x16,
  "7": 0x1A,
  "8": 0x1C,
  "9": 0x19,
  "0": 0x1D,

  "=": 0x18,
  "-": 0x1B,
  "]": 0x1E,
  "[": 0x21,
  "'": 0x27,
  ";": 0x29,
  "\\": 0x2A,
  ",": 0x2B,
  "/": 0x2C,
  ".": 0x2F,
  "~": 0x32,

  "Return": 0x24,
  "Tab": 0x30,
  "Space": 0x31,
  "Delete": 0x33,
  "Enter": 0x34,
  "Escape": 0x35,
  "RightCommand": 0x36,
  "Command": 0x37,
  "Shift": 0x38,
  "CapsLock": 0x39,
  "Option": 0x3A,
  "Control": 0x3B,
  "RightShift": 0x3C,
  "RightOption": 0x3D,
  "RightControl": 0x3E,
  "Function": 0x3F,
  "VolumeUp": 0x48,
  "VolumeDown": 0x49,
  "Mute": 0x4A,

  "KeypadDecimal": 0x41,
  "KeypadMultiply": 0x43,
  "KeypadPlus": 0x45,
  "KeypadClear": 0x47,
  "KeypadDivide": 0x4B,
  "KeypadEnter": 0x4C,
  "KeypadMinus": 0x4E,
  "KeypadEquals": 0x51,
  "Keypad0": 0x52,
  "Keypad1": 0x53,
  "Keypad2": 0x54,
  "Keypad3": 0x55,
  "Keypad4": 0x56,
  "Keypad5": 0x57,
  "Keypad6": 0x58,
  "Keypad7": 0x59,
  "Keypad8": 0x5B,
  "Keypad9": 0x5C,

  "F1": 0x7A,
  "F2": 0x78,
  "F3": 0x63,
  "F4": 0x76,
  "F5": 0x60,
  "F6": 0x61,
  "F7": 0x62,
  "F8": 0x64,
  "F9": 0x65,
  "F10": 0x6D,
  "F11": 0x67,
  "F12": 0x6F,
  "F13": 0x69,
  "F14": 0x6B,
  "F15": 0x71,
  "F16": 0x6A,
  "F17": 0x40,
  "F18": 0x4F,
  "F19": 0x50,
  "F20": 0x5A,

  "Help": 0x72,
  "Home": 0x73,
  "PageUp": 0x74,
  "ForwardDelete": 0x75,
  "End": 0x77,
  "PageDown": 0x79,
  "LeftArrow": 0x7B,
  "RightArrow": 0x7C,
  "DownArrow": 0x7D,
  "UpArrow": 0x7E,
]
