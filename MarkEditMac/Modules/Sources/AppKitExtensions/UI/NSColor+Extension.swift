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

  /**
   Returns true if the color is **strongly tinted**.
   */
  var isTintedColor: Bool {
    guard cgColor.alpha > 0.05, let color = usingColorSpace(.deviceRGB) else {
      return false
    }

    var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0
    color.getRed(&red, green: &green, blue: &blue, alpha: nil)

    let maxValue = max(red, green, blue)
    let minValue = min(red, green, blue)
    let valueDelta = maxValue - minValue

    let lightness = (maxValue + minValue) * 0.5
    let saturation = valueDelta == 0 ? 0 : (valueDelta / (1 - abs(2 * lightness - 1)))

    if lightness >= 0.9 {
      return saturation >= 0.12
    } else {
      return saturation >= 0.12 && (1 - lightness) >= 0.08
    }
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
