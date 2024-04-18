//
//  BackgroundTheming.swift
//
//  Created by cyan on 1/31/23.
//

import AppKit
import AppKitExtensions

public protocol BackgroundTheming: NSView {}

public extension BackgroundTheming {
  @MainActor
  func setBackgroundColor(_ color: NSColor) {
    layerBackgroundColor = color
    needsDisplay = true

    enumerateDescendants { (button: NonBezelButton) in
      button.layerBackgroundColor = color
      button.needsDisplay = true
    }
  }
}
