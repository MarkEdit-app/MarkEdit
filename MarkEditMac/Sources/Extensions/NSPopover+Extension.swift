//
//  NSPopover+Extension.swift
//  MarkEditMac
//
//  Created by cyan on 2024/8/22.
//

import AppKit

extension NSPopover {
  var sourceView: NSView? {
    value(forKey: "positioningView") as? NSView
  }
}
