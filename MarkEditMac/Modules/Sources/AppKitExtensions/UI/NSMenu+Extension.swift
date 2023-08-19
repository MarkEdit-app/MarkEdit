//
//  NSMenu+Extension.swift
//
//  Created by cyan on 12/26/22.
//

import AppKit

public extension NSMenu {
  var superMenuItem: NSMenuItem? {
    supermenu?.items.first { $0.submenu === self }
  }

  var copiedMenu: NSMenu? {
    copy() as? NSMenu
  }

  @discardableResult
  func addItem(withTitle string: String, action selector: Selector? = nil) -> NSMenuItem {
    addItem(withTitle: string, action: selector, keyEquivalent: "")
  }

  @discardableResult
  func addItem(withTitle string: String, action: @escaping () -> Void) -> NSMenuItem {
    let item = addItem(withTitle: string, action: nil)
    item.addAction(action)
    return item
  }

  /// Force an update, the .update() method doesn't work reliably.
  func reloadItems() {
    let item = NSMenuItem.separator()
    addItem(item)
    removeItem(item)
  }

  func isDescendantOf(menu: NSMenu?) -> Bool {
    guard let menu else {
      return false
    }

    var node: NSMenu? = self
    while node != nil {
      if node === menu {
        return true
      }

      node = node?.supermenu
    }

    return false
  }
}
