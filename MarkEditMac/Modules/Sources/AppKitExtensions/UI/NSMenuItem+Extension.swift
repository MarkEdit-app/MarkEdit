//
//  NSMenuItem+Extension.swift
//
//  Created by cyan on 12/25/22.
//

import AppKit

public extension NSMenuItem {
  static var systemWritingToolsItem: Self? {
    let selector = sel_getUid("standardWritingToolsMenuItem")
    guard responds(to: selector) else {
      return nil
    }

    return perform(selector)?.takeUnretainedValue() as? Self
  }

  convenience init(title: String) {
    self.init(title: title, action: nil, keyEquivalent: "")
  }

  var copiedItem: NSMenuItem? {
    copy() as? NSMenuItem
  }

  func setOn(_ on: Bool) {
    state = on ? .on : .off
  }

  func toggle() {
    state.toggle()
  }

  /**
   Enable or disable an item, recursively if it contains a submenu.

   This is useful for disabling a menu while still allowing its items to be viewed.
   */
  func setEnabledRecursively(isEnabled: Bool) {
    if let submenu {
      submenu.autoenablesItems = false
      submenu.items.forEach {
        $0.setEnabledRecursively(isEnabled: isEnabled)
      }
    } else {
      self.isEnabled = isEnabled && target != nil && action != nil
    }
  }

  @MainActor
  func performAction() {
    guard let action else {
      return
    }

    NSApp.sendAction(action, to: target, from: self)
  }

  func ensureImageVisibility() {
    guard #available(macOS 27.0, *) else {
      return
    }

  #if canImport(FoundationModels, _version: 2)
    preferredImageVisibility = .visible
  #else
    let selector = sel_getUid("setPreferredImageVisibility:")
    if responds(to: selector) {
      unsafeBitCast(
        method(for: selector),
        to: (@convention(c) (NSMenuItem, Selector, Int) -> Void).self
      )(self, selector, 1) // .visible
    } else {
      assertionFailure("Missing setPreferredImageVisibility:")
    }
  #endif
  }
}

extension NSControl.StateValue {
  mutating func toggle() {
    self = self == .on ? .off : .on
  }
}
