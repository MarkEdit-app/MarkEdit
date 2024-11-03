//
//  NSViewController+Extension.swift
//
//  Created by cyan on 1/8/23.
//

import AppKit

public extension NSViewController {
  var popover: NSPopover? {
    view.window?.value(forKey: "_popover") as? NSPopover
  }

  var isWindowVisible: Bool {
    view.window?.isVisible ?? false
  }
}
