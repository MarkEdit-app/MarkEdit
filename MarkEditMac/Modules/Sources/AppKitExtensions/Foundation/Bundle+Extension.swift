//
//  Bundle+Extension.swift
//
//  Created by cyan on 11/1/23.
//

import AppKit

public extension Bundle {
  static var webkitBundle: Self? {
    Self(identifier: "com.apple.WebKit")
  }

  var shortVersionString: String? {
    infoDictionary?["CFBundleShortVersionString"] as? String
  }

  var bundleVersion: String? {
    infoDictionary?["CFBundleVersion"] as? String
  }

  var userAgent: String {
    "MarkEdit/\(shortVersionString ?? "0.0.0")"
  }

  func isDefaultApp(toOpen url: URL) -> Bool {
    guard let defaultAppURL = NSWorkspace.shared.urlForApplication(toOpen: url) else {
      return false
    }

    guard let defaultAppBundleID = Bundle(url: defaultAppURL)?.bundleIdentifier else {
      return false
    }

    return defaultAppBundleID == bundleIdentifier
  }
}
