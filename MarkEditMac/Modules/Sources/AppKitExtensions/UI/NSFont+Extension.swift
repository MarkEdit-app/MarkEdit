//
//  NSFont+Extension.swift
//
//  Created by cyan on 1/29/23.
//

import AppKit

public extension NSFont {
  var cssFontFamily: String {
    familyName ?? fontName
  }

  var cssFontWeight: String? {
    guard let traits = fontDescriptor.object(forKey: .traits) as? [NSFontDescriptor.TraitKey: Any],
          let weight = traits[.weight] as? Double, weight != NSFont.Weight.regular.rawValue,
          let index = (Self.sortedWeights.firstIndex { $0.rawValue > weight }) else {
      return nil
    }

    // https://developer.mozilla.org/en-US/docs/Web/CSS/font-weight
    return String(index * 100)
  }

  var cssFontStyle: String? {
    // https://developer.mozilla.org/en-US/docs/Web/CSS/font-style
    if fontDescriptor.symbolicTraits.contains(.italic) {
      return "italic"
    }

    return nil
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

  convenience init?(name: String) {
    self.init(name: name, size: NSFont.systemFontSize)
  }
}

// MARK: - Private

private extension NSFont {
  static let sortedWeights: [NSFont.Weight] = [
    .ultraLight,
    .thin,
    .light,
    .regular,
    .medium,
    .semibold,
    .bold,
    .heavy,
    .black,
    .init(100), // Impossible value as an upper bound
  ].sorted {
      // In css, "ultra light" is thicker than "thin", it is the opposite in Cocoa,
      // sort to avoid unexpected behaviors.
      //
      // Note these values are not 1:1 mapping.
      $0.rawValue < $1.rawValue
    }

  func withDesign(_ design: NSFontDescriptor.SystemDesign) -> NSFont {
    guard let descriptor = fontDescriptor.withDesign(design) else {
      return self
    }

    return NSFont(descriptor: descriptor, size: pointSize) ?? self
  }
}
