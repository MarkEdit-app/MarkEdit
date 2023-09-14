//
//  FontStyle.swift
//
//  Created by cyan on 1/29/23.
//

import AppKit
import AppKitExtensions

/**
 FontStyle is an abstraction of either system fonts or custom fonts.

 For now, system fonts are all default, while custom fonts can have weight or style specified.
 */
@frozen public enum FontStyle: Codable {
  case systemDefault
  case systemMono
  case systemRounded
  case systemSerif
  case customFont(name: String)

  public var cssFontFamily: String {
    switch self {
    case .systemDefault:
      return "system-ui"
    case .systemMono:
      return "ui-monospace"
    case .systemRounded:
      return "ui-rounded"
    case .systemSerif:
      return "ui-serif"
    case let .customFont(name):
      return NSFont(name: name)?.cssFontFamily ?? name
    }
  }

  public var cssFontWeight: String? {
    if case let .customFont(name) = self {
      return NSFont(name: name)?.cssFontWeight
    }

    return nil
  }

  public var cssFontStyle: String? {
    if case let .customFont(name) = self {
      return NSFont(name: name)?.cssFontStyle
    }

    return nil
  }

  public func fontWith(size: Double, weight: NSFont.Weight = .regular) -> NSFont {
    switch self {
    case .systemDefault:
      return .systemFont(ofSize: size, weight: weight)
    case .systemMono:
      return .monospacedSystemFont(ofSize: size, weight: weight)
    case .systemRounded:
      return .roundedSystemFont(ofSize: size, weight: weight)
    case .systemSerif:
      return .serifSystemFont(ofSize: size, weight: weight)
    case let .customFont(name):
      return NSFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: weight)
    }
  }
}
