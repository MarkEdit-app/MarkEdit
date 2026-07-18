//
//  Notification+Extension.swift
//
//  Created by cyan on 1/30/23.
//

import Foundation

public extension Notification.Name {
  /// Posted when the font size is changed in the app.
  static let fontSizeChanged = Self("app.cyan.markedit.fontSizeChanged")
}

extension NotificationCenter {
  var fontSizePublisher: NotificationCenter.Publisher {
    publisher(for: .fontSizeChanged)
  }
}
