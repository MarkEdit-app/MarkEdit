//
//  NSImage+Extension.swift
//
//  Created by cyan on 1/15/23.
//

import AppKit

public extension NSImage {
  static func with(
    symbolName: String,
    pointSize: Double,
    weight: NSFont.Weight = .regular,
    accessibilityLabel: String? = nil
  ) -> NSImage {
    let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: accessibilityLabel)
    let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: weight)

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
}
