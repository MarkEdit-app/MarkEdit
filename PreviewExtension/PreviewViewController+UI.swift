//
//  PreviewViewController+UI.swift
//  PreviewExtension
//
//  Created by cyan on 5/26/26.
//

import AppKit
import SwiftUI
import MarkEditCore

extension PreviewViewController {
  var isRightToLeft: Bool {
    view.userInterfaceLayoutDirection == .rightToLeft
  }

  func updateAppearance() {
    let appearance = NSAppearance(named: isDarkMode ? .darkAqua : .aqua)
    view.layer?.backgroundColor = isDarkMode
      ? NSColor(red: 13.0 / 255, green: 17.0 / 255, blue: 22.0 / 255, alpha: 1).cgColor
      : NSColor.white.cgColor

    webView.appearance = appearance
    guidanceView?.appearance = appearance
  }

  func showSetUpGuidance() {
    // Terminal state, the preview is never prepared again for this instance
    webView.removeFromSuperview()
    guidanceView?.removeFromSuperview()

    let contentView = NSHostingView(rootView: {
      VStack(spacing: 10) {
        Image(systemName: Constants.guidanceIcon)
          .font(.largeTitle)
          .accessibilityHidden(true)
        Text(Constants.guidanceMessage)
          .font(.body)
          .multilineTextAlignment(.center)
      }
      .foregroundStyle(.secondary)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding()
    }())

    // Respects forcedColorScheme
    contentView.appearance = webView.appearance
    guidanceView = contentView
    view.addSubview(contentView)
    view.needsLayout = true
  }
}

// MARK: - Private

private extension PreviewViewController {
  enum Constants {
    static let guidanceIcon = "exclamationmark.bubble"
    static let guidanceMessage = String(
      localized: "Open MarkEdit to complete the setup.",
      comment: "Message of the QuickLook setup guidance"
    )
  }

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
