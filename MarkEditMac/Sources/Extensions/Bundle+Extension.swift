//
//  Bundle+Extension.swift
//  MarkEditMac
//
//  Created by cyan on 6/11/25.
//

import AppKit

extension Bundle {
  static let swizzleInfoDictionaryOnce: () = {
    guard #available(macOS 26.0, *), AppRuntimeConfig.useClassicInterface else {
      return
    }

    Bundle.exchangeInstanceMethods(
      originalSelector: #selector(getter: infoDictionary),
      swizzledSelector: #selector(getter: swizzled_infoDictionary)
    )
  }()

  @objc var swizzled_infoDictionary: NSDictionary? {
    let dict = NSMutableDictionary(dictionary: self.swizzled_infoDictionary ?? [:])
    dict["UIDesignRequiresCompatibility"] = true

    return dict
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
