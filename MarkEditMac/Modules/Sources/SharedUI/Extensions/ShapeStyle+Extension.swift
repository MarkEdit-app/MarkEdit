//
//  ShapeStyle+Extension.swift
//
//  Created by cyan on 7/24/26.
//

import SwiftUI

public extension ShapeStyle where Self == LinearGradient {
  /// Blue-to-orange spectrum sweep, drawn left to right.
  static var spectrum: LinearGradient {
    LinearGradient(
      gradient: Gradient(stops: [
        .init(color: Color(hex: 0x0894FF), location: 0.0),
        .init(color: Color(hex: 0x6C7BFF), location: 0.2),
        .init(color: Color(hex: 0xC959DD), location: 0.6),
        .init(color: Color(hex: 0xFF2E54), location: 0.8),
        .init(color: Color(hex: 0xFF9004), location: 1.0),
      ]),
      startPoint: .leading,
      endPoint: .trailing
    )
  }
}
