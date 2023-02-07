//
//  BackgroundTheming.swift
//
//  Created by cyan on 1/31/23.
//

import AppKit
import AppKitExtensions

public protocol BackgroundTheming: NSView {}

public extension BackgroundTheming {
  func setBackgroundColor(_ color: NSColor) {
    layerBackgroundColor = color
    needsDisplay = true

    enumerateChildren { (button: NonBezelButton) in
      button.layerBackgroundColor = color
      button.needsDisplay = true
    }
  }
}
