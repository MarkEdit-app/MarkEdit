//
//  NSColor+Extension.swift
//
//  Created by cyan on 12/17/22.
//

import AppKit

// MARK: - Semantic Colors

public extension NSColor {
  static var plainButtonBorder: NSColor {
    .theme(light: NSColor(white: 0, alpha: 0.3), dark: NSColor(white: 1, alpha: 0.3))
  }

  static var plainButtonHighlighted: NSColor {
    .theme(light: NSColor(white: 0, alpha: 0.1), dark: NSColor(white: 1, alpha: 0.1))
  }

  static var pushButtonBackground: NSColor {
    .theme(light: .white, dark: NSColor(hexCode: 0x565a61))
  }

  static var modernButtonBackground: NSColor {
    .theme(light: NSColor(white: 0, alpha: 0.08), dark: NSColor(white: 1, alpha: 0.066))
  }
}

// MARK: - Convenience Methods

public extension NSColor {
  convenience init(hexCode: UInt32, alpha: Double = 1.0) {
    let red = Double((hexCode & 0xFF0000) >> 16) / 255.0
    let green = Double((hexCode & 0x00FF00) >> 8) / 255.0
    let blue = Double(hexCode & 0x0000FF) / 255.0
    self.init(red: red, green: green, blue: blue, alpha: alpha)
  }

  static func theme(light: NSColor, dark: NSColor) -> NSColor {
    NSColor(name: nil) { $0.isDarkMode ? dark : light }
  }

  static func theme(lightHexCode: UInt32, darkHexCode: UInt32, alpha: Double = 1.0) -> NSColor {
    theme(
      light: NSColor(hexCode: lightHexCode, alpha: alpha),
      dark: NSColor(hexCode: darkHexCode, alpha: alpha)
    )
  }

  @MainActor
  func resolvedColor(with appearance: NSAppearance = NSApp.effectiveAppearance) -> NSColor {
    var cgColor: CGColor?
    appearance.performAsCurrentDrawingAppearance {
      cgColor = self.cgColor
    }

    return NSColor(cgColor: cgColor ?? self.cgColor) ?? self
  }
}
