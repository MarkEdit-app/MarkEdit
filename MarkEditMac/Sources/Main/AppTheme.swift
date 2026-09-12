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
  let colorPattern: [String]
  // Enables editor-colored tinting for translucent surfaces.
  let prefersTintedColors: Bool

  @MainActor static var current: Self {
    NSApplication.shared.isDarkMode ? darkTheme : lightTheme
  }

  static func withName(_ name: String) -> Self {
    allCases.first { $0.editorTheme == name } ?? GitHubLight
  }

  /// Get a "resolved" appearance name based on the current effective appearance.
  @MainActor var resolvedAppearance: NSAppearance? {
    NSAppearance(named: NSApp.effectiveAppearance.resolvedName(isDarkMode: isDark))
  }

  /// Illustration of the theme's color pattern.
  @MainActor var patternImage: NSImage {
    let length = 10.0
    let spacing = 2.0
    let colors = colorPattern.map {
      NSColor(hexCode: UInt32($0.dropFirst(), radix: 16) ?? 0)
    }

    let size = CGSize(
      width: Double(colors.count) * length + Double(max(colors.count - 1, 0)) * spacing + 4,
      height: length
    )

    return NSImage(size: size, flipped: false) { _ in
      for (index, color) in colors.enumerated() {
        let rect = CGRect(
          x: Double(index) * (length + spacing),
          y: 0,
          width: length,
          height: length
        )

        color.setFill()
        NSBezierPath(roundedRect: rect, xRadius: 2, yRadius: 2).fill()

        NSColor.black.withAlphaComponent(0.4).setStroke()
        let border = NSBezierPath(
          roundedRect: rect.insetBy(dx: 0.25, dy: 0.25),
          xRadius: 1.75,
          yRadius: 1.75
        )

        border.lineWidth = 0.5
        border.stroke()
      }

      return true
    }
  }

  /// Trigger theme update for all editors.
  @MainActor
  func updateAppearance(animateChanges: Bool = false) {
    EditorPreloader.shared.viewControllers().forEach {
      $0.setTheme(self, animated: animateChanges)
    }
  }
}

// MARK: - Themes

extension AppTheme: CaseIterable, Hashable {
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
      colorPattern: ["#ffffff", "#1f2328", "#0550ae", "#cf222e", "#0a3069"],
      prefersTintedColors: false
    )
  }

  static var GitHubDark: Self {
    Self(
      isDark: true,
      editorTheme: "github-dark",
      windowBackground: NSColor(hexCode: 0x0d1117),
      colorPattern: ["#0d1117", "#e6edf3", "#79c0ff", "#ff7b72", "#a5d6ff"],
      prefersTintedColors: true
    )
  }

  static var XcodeLight: Self {
    Self(
      isDark: false,
      editorTheme: "xcode-light",
      windowBackground: NSColor(hexCode: 0xffffff),
      colorPattern: ["#ffffff", "#000000", "#0b4f79", "#9b2393", "#c41a16"],
      prefersTintedColors: false
    )
  }

  static var XcodeDark: Self {
    Self(
      isDark: true,
      editorTheme: "xcode-dark",
      windowBackground: NSColor(hexCode: 0x1f1f24),
      colorPattern: ["#1f1f24", "#dedede", "#5dd8ff", "#fc5fa3", "#fc6a5d"],
      prefersTintedColors: true
    )
  }

  static var Dracula: Self {
    Self(
      isDark: true,
      editorTheme: "dracula",
      windowBackground: NSColor(hexCode: 0x282a36),
      colorPattern: ["#282a36", "#f8f8f2", "#bd93f9", "#ff79c6", "#f1fa8c"],
      prefersTintedColors: true
    )
  }

  static var Cobalt: Self {
    Self(
      isDark: true,
      editorTheme: "cobalt",
      windowBackground: NSColor(hexCode: 0x193549),
      colorPattern: ["#193549", "#e1efff", "#ffc600", "#ff9d00", "#a5ff90"],
      prefersTintedColors: true
    )
  }

  static var WinterIsComingLight: Self {
    Self(
      isDark: false,
      editorTheme: "winter-is-coming-light",
      windowBackground: NSColor(hexCode: 0xffffff),
      colorPattern: ["#ffffff", "#3e3e3e", "#034c7c", "#0991b6", "#a44185"],
      prefersTintedColors: false
    )
  }

  static var WinterIsComingDark: Self {
    Self(
      isDark: true,
      editorTheme: "winter-is-coming-dark",
      windowBackground: NSColor(hexCode: 0x282822),
      colorPattern: ["#282822", "#ffffff", "#5abeb0", "#00bff9", "#bcf0c0"],
      prefersTintedColors: true
    )
  }

  static var MinimalLight: Self {
    Self(
      isDark: false,
      editorTheme: "minimal-light",
      windowBackground: NSColor(hexCode: 0xffffff),
      colorPattern: ["#ffffff", "#3a3a3c", "#000000", "#3a3a3c", "#000000"],
      prefersTintedColors: false
    )
  }

  static var MinimalDark: Self {
    Self(
      isDark: true,
      editorTheme: "minimal-dark",
      windowBackground: NSColor(hexCode: 0x1e1e1e),
      colorPattern: ["#1e1e1e", "#d1d1d6", "#ffffff", "#d1d1d6", "#ffffff"],
      prefersTintedColors: true
    )
  }

  static var SynthWave84: Self {
    Self(
      isDark: true,
      editorTheme: "synthwave84",
      windowBackground: NSColor(hexCode: 0x262335),
      colorPattern: ["#262335", "#f0eff1", "#f92aad", "#f4eee4", "#ff8b39"],
      prefersTintedColors: true
    )
  }

  static var NightOwl: Self {
    Self(
      isDark: true,
      editorTheme: "night-owl",
      windowBackground: NSColor(hexCode: 0x011627),
      colorPattern: ["#011627", "#d6deeb", "#82b1ff", "#c792ea", "#ecc48d"],
      prefersTintedColors: true
    )
  }

  static var RosePineDawn: Self {
    Self(
      isDark: false,
      editorTheme: "rose-pine-dawn",
      windowBackground: NSColor(hexCode: 0xfaf4ed),
      colorPattern: ["#faf4ed", "#575279", "#56949f", "#286983", "#ea9d34"],
      prefersTintedColors: true
    )
  }

  static var RosePine: Self {
    Self(
      isDark: true,
      editorTheme: "rose-pine",
      windowBackground: NSColor(hexCode: 0x191724),
      colorPattern: ["#191724", "#e0def4", "#9ccfd8", "#31748f", "#f6c177"],
      prefersTintedColors: true
    )
  }

  static var SolarizedLight: Self {
    Self(
      isDark: false,
      editorTheme: "solarized-light",
      windowBackground: NSColor(hexCode: 0xfdf6e3),
      colorPattern: ["#fdf6e3", "#586e75", "#268bd2", "#859900", "#2aa198"],
      prefersTintedColors: true
    )
  }

  static var SolarizedDark: Self {
    Self(
      isDark: true,
      editorTheme: "solarized-dark",
      windowBackground: NSColor(hexCode: 0x002b36),
      colorPattern: ["#002b36", "#93a1a1", "#268bd2", "#859900", "#2aa198"],
      prefersTintedColors: true
    )
  }

  var displayName: String {
    switch self {
    case Self.GitHubLight, Self.GitHubDark:
      return "GitHub"
    case Self.XcodeLight, Self.XcodeDark:
      return "Xcode"
    case Self.Dracula:
      return "Dracula"
    case Self.Cobalt:
      return "Cobalt"
    case Self.WinterIsComingLight, Self.WinterIsComingDark:
      return "Winter is Coming"
    case Self.MinimalLight, Self.MinimalDark:
      return "Minimal"
    case Self.SynthWave84:
      return "SynthWave '84"
    case Self.NightOwl:
      return "Night Owl"
    case Self.RosePineDawn:
      return "Rosé Pine Dawn"
    case Self.RosePine:
      return "Rosé Pine"
    case Self.SolarizedLight, Self.SolarizedDark:
      return "Solarized"
    default:
      fatalError("Invalid theme was found")
    }
  }
}

// MARK: - Private

@MainActor
private extension AppTheme {
  static var lightTheme: Self {
    withName(AppPreferences.Editor.lightTheme)
  }

  static var darkTheme: Self {
    withName(AppPreferences.Editor.darkTheme)
  }
}
