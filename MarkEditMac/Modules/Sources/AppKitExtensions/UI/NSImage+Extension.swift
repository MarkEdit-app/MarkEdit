//
//  NSImage+Extension.swift
//
//  Created by cyan on 1/15/23.
//

import AppKit
import SwiftUI

public extension NSImage {
  static func with(
    symbolName: String,
    pointSize: Double,
    weight: NSFont.Weight = .regular,
    accessibilityLabel: String? = nil
  ) -> NSImage {
    let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: accessibilityLabel)
    let config = Self.SymbolConfiguration(pointSize: pointSize, weight: weight)

    guard let image = image?.withSymbolConfiguration(config) else {
      assertionFailure("Failed to create image with symbol \"\(symbolName)\"")
      return NSImage()
    }

    return image
  }

  func resized(with size: CGSize) -> NSImage {
    let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
    guard let representation = bestRepresentation(for: frame, context: nil, hints: nil) else {
      return self
    }

    let image = NSImage(size: size, flipped: false) { _ in
      representation.draw(in: frame)
    }

    return image
  }

  func setTintColor(_ tintColor: NSColor?) {
    guard responds(to: sel_getUid("_setTintColor:")) else {
      return assertionFailure("Missing _setTintColor(_:) to change the tint color")
    }

    perform(sel_getUid("_setTintColor:"), with: tintColor)
  }
}

public extension Image {
  static func alwaysVisibleSymbol(named symbolName: String) -> Self {
    guard #available(macOS 27.0, *) else {
      return Self(systemName: symbolName)
    }

    guard let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) else {
      assertionFailure("Failed to create image with symbol \"\(symbolName)\"")
      return Self(systemName: symbolName)
    }

    // [macOS 27] FB23544345 SwiftUI lack of support for preferred image visibility
    let redrawn = image.resized(with: image.size)
    redrawn.isTemplate = true
    return Self(nsImage: redrawn)
  }
}
