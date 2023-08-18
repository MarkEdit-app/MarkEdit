//
//  WKWebViewConfiguration+Extension.swift
//
//  Created by cyan on 1/7/23.
//

import WebKit

public extension WKWebViewConfiguration {
  static func newConfig() -> WKWebViewConfiguration {
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

    return config
  }

  var supportsInlinePredictions: Bool {
    guard #available(macOS 14.0, *) else {
      return false
    }

    #if compiler(>=5.9)
      return true
    #else
      return responds(to: sel_getUid("setAllowsInlinePredictions:"))
    #endif
  }

  func setAllowsInlinePredictions(_ newValue: Bool) {
    guard supportsInlinePredictions else {
      return
    }

    #if compiler(>=5.9)
      if #available(macOS 14.0, *) {
        allowsInlinePredictions = newValue
      }
    #else
      setValue(newValue, forKey: "allowsInlinePredictions")
    #endif
  }
}
