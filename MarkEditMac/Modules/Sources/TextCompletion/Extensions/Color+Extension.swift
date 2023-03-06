//
//  Color+Extension.swift
//
//  Created by cyan on 3/4/23.
//

import AppKit
import SwiftUI

extension Color {
  static var accent: Self {
    Color(nsColor: .controlAccentColor)
  }

  static var label: Self {
    Color(nsColor: .labelColor)
  }
}
