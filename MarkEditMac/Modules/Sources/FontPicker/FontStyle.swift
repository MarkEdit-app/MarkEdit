//
//  FontStyle.swift
//
//  Created by cyan on 1/29/23.
//

import AppKit
import AppKitExtensions

/**
 FontStyle is an abstraction of either system fonts or custom fonts.
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
      return name
    }
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
