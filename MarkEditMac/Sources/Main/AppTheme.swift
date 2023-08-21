//
//  AppTheme.swift
//  MarkEditMac
//
//  Created by cyan on 12/17/22.
//

import AppKit

struct AppTheme {
  let isDark: Bool
  let editorTheme: String
  // Pre-defined colors to style the window for initial launch
  let windowBackground: NSColor
  // If true, the toolbar has more tinted effect based on windowBackground,
  // usually it's for dark themes, some light themes also need this, such as solarized.
  let prefersTintedToolbar: Bool

  static var current: Self {
    NSApplication.shared.isDarkMode ? darkTheme : lightTheme
  }

  static func withName(_ name: String) -> Self {
    allCases.first { $0.editorTheme == name } ?? GitHubLight
  }

  /// Get a "resolved" appearance name based on the current effective appearance.
  var resolvedAppearance: NSAppearance? {
    NSAppearance(named: NSApp.effectiveAppearance.resolvedName(isDarkMode: isDark))
  }

  /// Trigger theme update for all editors.
  func updateAppearance(animateChanges: Bool = false) {
    EditorReusePool.shared.viewControllers().forEach {
      $0.setTheme(self, animated: animateChanges)
    }
  }
}

// MARK: - Themes

extension AppTheme: CaseIterable, Hashable, CustomStringConvertible {
  static var allCases: [AppTheme] {
    [
      GitHubLight, GitHubDark,
      XcodeLight, XcodeDark,
      Dracula,
      Cobalt,
      WinterIsComingLight, WinterIsComingDark,
      MinimalLight, MinimalDark,
      SynthWave84,
      NightOwl,
      RosePineDawn, RosePine,
      SolarizedLight, SolarizedDark,
    ]
  }

  static var GitHubLight: Self {
    Self(
      isDark: false,
      editorTheme: "github-light",
      windowBackground: NSColor(hexCode: 0xffffff),
      prefersTintedToolbar: false
    )
  }

  static var GitHubDark: Self {
    Self(
      isDark: true,
      editorTheme: "github-dark",
      windowBackground: NSColor(hexCode: 0x0d1116),
      prefersTintedToolbar: true
    )
  }

  static var XcodeLight: Self {
    Self(
      isDark: false,
      editorTheme: "xcode-light",
      windowBackground: NSColor(hexCode: 0xffffff),
      prefersTintedToolbar: false
    )
  }

  static var XcodeDark: Self {
    Self(
      isDark: true,
      editorTheme: "xcode-dark",
      windowBackground: NSColor(hexCode: 0x1f1f24),
      prefersTintedToolbar: true
    )
  }

  static var Dracula: Self {
    Self(
      isDark: true,
      editorTheme: "dracula",
      windowBackground: NSColor(hexCode: 0x282a36),
      prefersTintedToolbar: true
    )
  }

  static var Cobalt: Self {
    Self(
      isDark: true,
      editorTheme: "cobalt",
      windowBackground: NSColor(hexCode: 0x193549),
      prefersTintedToolbar: true
    )
  }

  static var WinterIsComingLight: Self {
    Self(
      isDark: false,
      editorTheme: "winter-is-coming-light",
      windowBackground: NSColor(hexCode: 0xffffff),
      prefersTintedToolbar: false
    )
  }

  static var WinterIsComingDark: Self {
    Self(
      isDark: true,
      editorTheme: "winter-is-coming-dark",
      windowBackground: NSColor(hexCode: 0x282822),
      prefersTintedToolbar: true
    )
  }

  static var MinimalLight: Self {
    Self(
      isDark: false,
      editorTheme: "minimal-light",
      windowBackground: NSColor(hexCode: 0xffffff),
      prefersTintedToolbar: false
    )
  }

  static var MinimalDark: Self {
    Self(
      isDark: true,
      editorTheme: "minimal-dark",
      windowBackground: NSColor(hexCode: 0x000000),
      prefersTintedToolbar: true
    )
  }

  static var SynthWave84: Self {
    Self(
      isDark: true,
      editorTheme: "synthwave84",
      windowBackground: NSColor(hexCode: 0x252335),
      prefersTintedToolbar: true
    )
  }

  static var NightOwl: Self {
    Self(
      isDark: true,
      editorTheme: "night-owl",
      windowBackground: NSColor(hexCode: 0x011627),
      prefersTintedToolbar: true
    )
  }

  static var RosePineDawn: Self {
    Self(
      isDark: false,
      editorTheme: "rose-pine-dawn",
      windowBackground: NSColor(hexCode: 0xfaf4ed),
      prefersTintedToolbar: true
    )
  }

  static var RosePine: Self {
    Self(
      isDark: true,
      editorTheme: "rose-pine",
      windowBackground: NSColor(hexCode: 0x191724),
      prefersTintedToolbar: true
    )
  }

  static var SolarizedLight: Self {
    Self(
      isDark: false,
      editorTheme: "solarized-light",
      windowBackground: NSColor(hexCode: 0xfdf6e3),
      prefersTintedToolbar: true
    )
  }

  static var SolarizedDark: Self {
    Self(
      isDark: true,
      editorTheme: "solarized-dark",
      windowBackground: NSColor(hexCode: 0x012b36),
      prefersTintedToolbar: true
    )
  }

  var description: String {
    switch self {
    case Self.GitHubLight:
      return "GitHub (Light)"
    case Self.GitHubDark:
      return "GitHub (Dark)"
    case Self.XcodeLight:
      return "Xcode (Light)"
    case Self.XcodeDark:
      return "Xcode (Dark)"
    case Self.Dracula:
      return "Dracula"
    case Self.Cobalt:
      return "Cobalt"
    case Self.WinterIsComingLight:
      return "Winter is Coming (Light)"
    case Self.WinterIsComingDark:
      return "Winter is Coming (Dark)"
    case Self.MinimalLight:
      return "Minimal (Light)"
    case Self.MinimalDark:
      return "Minimal (Dark)"
    case Self.SynthWave84:
      return "SynthWave '84"
    case Self.NightOwl:
      return "Night Owl"
    case Self.RosePineDawn:
      return "Rosé Pine Dawn"
    case Self.RosePine:
      return "Rosé Pine"
    case Self.SolarizedLight:
      return "Solarized (Light)"
    case Self.SolarizedDark:
      return "Solarized (Dark)"
    default:
      fatalError("Invalid theme was found")
    }
  }
}

// MARK: - Private

private extension AppTheme {
  static var lightTheme: Self {
    withName(AppPreferences.Editor.lightTheme)
  }

  static var darkTheme: Self {
    withName(AppPreferences.Editor.darkTheme)
  }
}
