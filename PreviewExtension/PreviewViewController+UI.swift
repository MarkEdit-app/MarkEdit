//
//  PreviewViewController+UI.swift
//  PreviewExtension
//
//  Created by cyan on 5/26/26.
//

import AppKit

extension PreviewViewController {
  var isDarkMode: Bool {
    switch NSApp.effectiveAppearance.name {
    case .darkAqua, .vibrantDark, .accessibilityHighContrastDarkAqua, .accessibilityHighContrastVibrantDark:
      return true
    default:
      return false
    }
  }

  var isRightToLeft: Bool {
    view.userInterfaceLayoutDirection == .rightToLeft
  }

  var effectiveTheme: String {
    isDarkMode ? "github-dark" : "github-light"
  }

  func updateBackgroundColor() {
    // To hide the transparent background of the scrolling overflow
    view.layer?.backgroundColor = (isDarkMode ? NSColor(red: 13.0 / 255, green: 17.0 / 255, blue: 22.0 / 255, alpha: 1) : NSColor.white).cgColor
  }

  func updateEditorTheme() {
    // To keep the app size smaller, we don't have bridge here,
    // construct script literals directly.
    webView.evaluateJavaScript("setTheme(`\(effectiveTheme)`)")
  }
}
