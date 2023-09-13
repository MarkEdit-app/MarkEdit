//
//  NSFont+Extension.swift
//
//  Created by cyan on 1/29/23.
//

import AppKit

public extension NSFont {
  var cssFontFamily: String {
    // If the font is bold or italic, we use its name directly,
    // because we want to apply the style to all scenarios.
    if isBoldOrItalic {
      return fontName
    }

    // Otherwise, we use its family name to avoid font synthesis,
    // which is buggy in WebKit on macOS, i.e., bold text gets bolder and blurry.
    return familyName ?? fontName
  }

  static func monospacedSystemFont(ofSize fontSize: Double) -> NSFont {
    monospacedSystemFont(ofSize: fontSize, weight: .regular)
  }

  static func roundedSystemFont(ofSize fontSize: Double, weight: NSFont.Weight = .regular) -> NSFont {
    .systemFont(ofSize: fontSize, weight: weight).withDesign(.rounded)
  }

  static func serifSystemFont(ofSize fontSize: Double, weight: NSFont.Weight = .regular) -> NSFont {
    .systemFont(ofSize: fontSize, weight: weight).withDesign(.serif)
  }
}

// MARK: - Private

private extension NSFont {
  var isBoldOrItalic: Bool {
    let traits = fontDescriptor.symbolicTraits
    return traits.contains(.bold) || traits.contains(.italic)
  }

  func withDesign(_ design: NSFontDescriptor.SystemDesign) -> NSFont {
    guard let descriptor = fontDescriptor.withDesign(design) else {
      return self
    }

    return NSFont(descriptor: descriptor, size: pointSize) ?? self
  }
}
