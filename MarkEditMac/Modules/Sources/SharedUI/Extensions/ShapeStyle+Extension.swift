//
//  ShapeStyle+Extension.swift
//
//  Created by cyan on 7/24/26.
//

import SwiftUI

public enum SpectrumDirection {
  case leftToRight
  case rightToLeft
}

public extension ShapeStyle where Self == LinearGradient {
  /// Blue-to-orange spectrum sweep; `direction` mirrors it horizontally.
  static func spectrum(direction: SpectrumDirection) -> Self {
    LinearGradient(
      stops: [
        .init(color: Color(hex: 0x0894FF), location: 0.0),
        .init(color: Color(hex: 0x6C7BFF), location: 0.2),
        .init(color: Color(hex: 0xC959DD), location: 0.6),
        .init(color: Color(hex: 0xFF2E54), location: 0.8),
        .init(color: Color(hex: 0xFF9004), location: 1.0),
      ],
      startPoint: direction == .leftToRight ? .leading : .trailing,
      endPoint: direction == .leftToRight ? .trailing : .leading
    )
  }
}
