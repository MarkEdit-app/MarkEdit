//
//  NSPopover+Extension.swift
//  MarkEditMac
//
//  Created by cyan on 8/22/24.
//

import AppKit

extension NSPopover {
  var sourceView: NSView? {
    value(forKey: "positioningView") as? NSView
  }
}
