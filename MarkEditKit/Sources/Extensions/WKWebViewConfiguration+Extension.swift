//
//  WKWebViewConfiguration+Extension.swift
//
//  Created by cyan on 1/7/23.
//

import WebKit
import MarkEditCore

public extension WKWebViewConfiguration {
  static func newConfig(disableCors: Bool = false, disabledFeatures: [String] = []) -> WKWebViewConfiguration {
    let config: WKWebViewConfiguration = .preferredConfig()
    config.enablePerformanceFlags(disabledFeatures: disabledFeatures)

    // Disable CORS checks entirely, allowing fetch() in user scripts to do lots of things.
    //
    // This shouldn't raise security issues, as we're not a browser that can load arbitrary URLs.
    if disableCors && !config.preferences.setBoolValue(false, forSelector: "_setWebSecurityEnabled:") {
      Logger.assertFail("Failed to call _setWebSecurityEnabled:")
    }

    return config
  }
}
