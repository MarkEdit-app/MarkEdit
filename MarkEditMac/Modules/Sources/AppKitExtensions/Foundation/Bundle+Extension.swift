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

  var shortVersionString: String {
    (infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0.0"
  }

  var bundleVersion: String? {
    infoDictionary?["CFBundleVersion"] as? String
  }

  var isAppleSiliconOnly: Bool {
    executableArchitectures?.map { $0.intValue } == [NSBundleExecutableArchitectureARM64]
  }

  var userAgent: String {
    "MarkEdit/\(shortVersionString)"
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
