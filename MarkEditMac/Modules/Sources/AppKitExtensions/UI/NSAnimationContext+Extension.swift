//
//  NSAnimationContext+Extension.swift
//
//  Created by cyan on 12/16/22.
//

import AppKit

public extension NSAnimationContext {
  static func runAnimationGroup(duration: TimeInterval, changes: (NSAnimationContext) -> Void, completionHandler: (() -> Void)? = nil) {
    runAnimationGroup({ context in
      context.duration = duration
      changes(context)
    }, completionHandler: completionHandler)
  }
}
