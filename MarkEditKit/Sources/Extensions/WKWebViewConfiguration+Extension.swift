//
//  WKWebViewConfiguration+Extension.swift
//
//  Created by cyan on 1/7/23.
//

import WebKit

public extension WKWebViewConfiguration {
  static func newConfig() -> Self {
    let config = Self()
    if config.responds(to: sel_getUid("_drawsBackground")) {
      // To mimic settable isOpaque on iOS,
      // which is required for the background color and initial white flash in dark mode
      config.setValue(false, forKey: "drawsBackground")
    } else {
      Logger.assertFail("Failed to overwrite drawsBackground in WKWebViewConfiguration")
    }

    // https://github.com/WebKit/WebKit/blob/main/Source/WebKit/UIProcess/API/Cocoa/WKPreferences.mm
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

    // [macOS 14] WebKit hasn't yet exposed this as public, even it's documented
    return responds(to: sel_getUid("setAllowsInlinePredictions:"))
  }

  func setAllowsInlinePredictions(_ allowsInlinePredictions: Bool) {
    guard supportsInlinePredictions else {
      return
    }

    // [macOS 14] WebKit hasn't yet exposed this as public, even it's documented
    setValue(allowsInlinePredictions, forKey: "allowsInlinePredictions")
  }
}
