//
//  Bundle+Extension.swift
//  MarkEditMac
//
//  Created by cyan on 6/11/25.
//

import AppKit

extension Bundle {
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
