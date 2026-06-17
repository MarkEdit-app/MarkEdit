//
//  UserDefaults+Extension.swift
//
//  Created by cyan on 6/17/26.
//

import Foundation

public enum ForcedColorScheme: String {
  case system
  case light
  case dark
}

public extension UserDefaults {
  static var forcedColorScheme: ForcedColorScheme {
    get {
      guard let value = appGroup?.string(forKey: forcedColorSchemeKey) else {
        return .system
      }

      return ForcedColorScheme(rawValue: value) ?? .system
    }
    set {
      guard newValue != .system else {
        appGroup?.removeObject(forKey: forcedColorSchemeKey)
        return
      }

      appGroup?.set(newValue.rawValue, forKey: forcedColorSchemeKey)
    }
  }
}

// MARK: - Private

private extension UserDefaults {
  static var appGroup: UserDefaults? {
    UserDefaults(suiteName: "group.app.cyan.markedit")
  }

  static let forcedColorSchemeKey = "forcedColorScheme"
}
