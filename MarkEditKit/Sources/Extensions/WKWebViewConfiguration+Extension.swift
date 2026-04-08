//
//  WKWebViewConfiguration+Extension.swift
//
//  Created by cyan on 1/7/23.
//

import WebKit
import MarkEditCore

public extension WKWebViewConfiguration {
  static func newConfig(disableCors: Bool = false) -> WKWebViewConfiguration {
    class Configuration: WKWebViewConfiguration {
      // To mimic settable isOpaque on iOS,
      // which is required for the background color and initial white flash in dark mode
      @objc func _drawsBackground() -> Bool { false }
    }

    let config = Configuration()
    config.enablePerformanceFlags()

    if !config.preferences.setBoolValue(true, forSelector: "_setDeveloperExtrasEnabled:") {
      Logger.assertFail("Failed to call _setDeveloperExtrasEnabled:")
    }

    // Disable CORS checks entirely, allowing fetch() in user scripts to do lots of things.
    //
    // This shouldn't raise security issues, as we're not a browser that can load arbitrary URLs.
    if disableCors && !config.preferences.setBoolValue(false, forSelector: "_setWebSecurityEnabled:") {
      Logger.assertFail("Failed to call _setWebSecurityEnabled:")
    }

    return config
  }
}
