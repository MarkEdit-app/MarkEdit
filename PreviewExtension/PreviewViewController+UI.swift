//
//  PreviewViewController+UI.swift
//  PreviewExtension
//
//  Created by cyan on 5/26/26.
//

import AppKit
import MarkEditCore

extension PreviewViewController {
  var isRightToLeft: Bool {
    view.userInterfaceLayoutDirection == .rightToLeft
  }

  func updateAppearance() {
    if isDarkMode {
      view.layer?.backgroundColor = NSColor(red: 13.0 / 255, green: 17.0 / 255, blue: 22.0 / 255, alpha: 1).cgColor
      webView.appearance = NSAppearance(named: .darkAqua)
    } else {
      view.layer?.backgroundColor = NSColor.white.cgColor
      webView.appearance = NSAppearance(named: .aqua)
    }
  }
}

// MARK: - Private

private extension PreviewViewController {
  var isDarkMode: Bool {
    switch UserDefaults.forcedColorScheme {
    case .dark:
      return true
    case .light:
      return false
    case .system:
      break
    }

    switch NSApp.effectiveAppearance.name {
    case .darkAqua, .vibrantDark, .accessibilityHighContrastDarkAqua, .accessibilityHighContrastVibrantDark:
      return true
    default:
      return false
    }
  }
}
