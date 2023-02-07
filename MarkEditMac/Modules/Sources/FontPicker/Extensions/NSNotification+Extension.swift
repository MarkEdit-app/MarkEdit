//
//  NSNotification+Extension.swift
//
//  Created by cyan on 1/30/23.
//

import Foundation

public extension NSNotification.Name {
  static let fontSizeChanged = Self("fontSizeChanged")
}

extension NotificationCenter {
  var fontSizePublisher: NotificationCenter.Publisher {
    publisher(for: .fontSizeChanged)
  }
}
