//
//  NSFont+Extension.swift
//
//  Created by cyan on 1/29/23.
//

import AppKit

public extension NSFont {
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
  func withDesign(_ design: NSFontDescriptor.SystemDesign) -> NSFont {
    guard let descriptor = fontDescriptor.withDesign(design) else {
      return self
    }

    return NSFont(descriptor: descriptor, size: pointSize) ?? self
  }
}
