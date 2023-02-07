//
//  NSAppearance+Extension.swift
//
//  Created by cyan on 1/24/23.
//

import AppKit

public extension NSAppearance {
  var isDarkMode: Bool {
    switch name {
    case .darkAqua, .vibrantDark, .accessibilityHighContrastDarkAqua, .accessibilityHighContrastVibrantDark:
      return true
    default:
      return false
    }
  }

  func resolvedName(isDarkMode: Bool) -> NSAppearance.Name {
    switch name {
    case .aqua, .darkAqua:
      // Aqua
      return isDarkMode ? .darkAqua : .aqua
    case .vibrantLight, .vibrantDark:
      // Vibrant
      return isDarkMode ? .vibrantDark : .vibrantLight
    case .accessibilityHighContrastAqua, .accessibilityHighContrastDarkAqua:
      // High contrast
      return isDarkMode ? .accessibilityHighContrastDarkAqua : .accessibilityHighContrastAqua
    case .accessibilityHighContrastVibrantLight, .accessibilityHighContrastVibrantDark:
      // High contrast vibrant
      return isDarkMode ? .accessibilityHighContrastVibrantDark : .accessibilityHighContrastVibrantLight
    default:
      return .aqua
    }
  }
}
