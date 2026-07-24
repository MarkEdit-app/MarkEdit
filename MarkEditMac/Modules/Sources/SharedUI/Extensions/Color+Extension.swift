//
//  Color+Extension.swift
//
//  Created by cyan on 7/24/26.
//

import SwiftUI

public extension Color {
  init(hex: Int) {
    let red = Double((hex >> 16) & 0xFF) / 255
    let green = Double((hex >> 8) & 0xFF) / 255
    let blue = Double(hex & 0xFF) / 255
    self.init(red: red, green: green, blue: blue)
  }
}
