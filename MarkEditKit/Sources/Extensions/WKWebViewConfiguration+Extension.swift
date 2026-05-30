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

    // Disable CORS for http/https requests, allowing fetch() in user scripts to read cross-origin responses.
    //
    // This is narrower than _setWebSecurityEnabled: it only relaxes CORS for network loads, without
    // granting universal access, so the same-origin policy still guards cross-origin DOM and file:// reads.
    if disableCors && !config.setObjectValue(["*://*/*"] as NSArray, forSelector: "_setCORSDisablingPatterns:") {
      Logger.assertFail("Failed to call _setCORSDisablingPatterns:")
    }

    return config
  }
}
