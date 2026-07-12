//
//  NSPopover+Extension.swift
//
//  Created by cyan on 8/22/24.
//

import AppKit

public extension NSPopover {
  var sourceView: NSView? {
    value(forKey: "positioningView") as? NSView
  }
}
