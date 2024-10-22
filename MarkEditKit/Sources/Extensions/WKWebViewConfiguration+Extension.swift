//
//  WKWebViewConfiguration+Extension.swift
//
//  Created by cyan on 1/7/23.
//

import WebKit

public extension WKWebViewConfiguration {
  static func newConfig(disableCors: Bool = false) -> WKWebViewConfiguration {
    class Configuration: WKWebViewConfiguration {
      // To mimic settable isOpaque on iOS,
      // which is required for the background color and initial white flash in dark mode
      @objc func _drawsBackground() -> Bool { false }
    }

    let config = Configuration()
    if config.preferences.responds(to: sel_getUid("_developerExtrasEnabled")) {
      config.preferences.setValue(true, forKey: "developerExtrasEnabled")
    } else {
      Logger.assertFail("Failed to overwrite developerExtrasEnabled in WKPreferences")
    }

    // Disable CORS checks entirely, allowing fetch() in user scripts to do lots of things.
    //
    // This shouldn't raise security issues, as we're not a browser that can load arbitrary URLs.
    if disableCors {
      if config.preferences.responds(to: sel_getUid("_webSecurityEnabled")) {
        config.preferences.setValue(false, forKey: "webSecurityEnabled")
      } else {
        Logger.assertFail("Failed to overwrite webSecurityEnabled in WKPreferences")
      }
    }

    return config
  }
}
