//
//  Image+Extension.swift
//
//  Created by cyan on 7/24/26.
//

import SwiftUI
import AppKitExtensions

public extension Image {
  static func alwaysVisibleSymbol(named symbolName: String) -> Self {
    guard #available(macOS 27.0, *) else {
      return Self(systemName: symbolName)
    }

    guard let image = NSImage(systemSymbolName: symbolName) else {
      assertionFailure("Failed to create image with symbol \"\(symbolName)\"")
      return Self(systemName: symbolName)
    }

    // [macOS 27] FB23544345 SwiftUI lack of support for preferred image visibility
    let redrawn = image.resized(with: image.size)
    redrawn.isTemplate = true
    return Self(nsImage: redrawn)
  }
}
