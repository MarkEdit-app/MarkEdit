//
//  WKWebViewConfiguration+Extension.swift
//
//  Created by cyan on 3/29/26.
//

import WebKit

public extension WKWebViewConfiguration {
  func enablePerformanceFlags() {
    // Launch the WebContent process at init time instead of deferring it to the first load.
    //
    // On macOS the default is to delay process launch until loadHTMLString is called,
    // but EditorViewController builds the HTML on a background queue before loading,
    // so the process can start in parallel rather than blocking on the first load call.
    if responds(to: sel_getUid("_setDelaysWebProcessLaunchUntilFirstLoad:")) {
      setValue(false, forKey: "delaysWebProcessLaunchUntilFirstLoad")
    }

    // Skip the blocking wait for the first rendered frame after the view joins a window.
    //
    // The default behavior synchronizes the first paint, which is unnecessary here
    // since the background color is already transparent (_drawsBackground returns false).
    if responds(to: sel_getUid("_setWaitsForPaintAfterViewDidMoveToWindow:")) {
      setValue(false, forKey: "waitsForPaintAfterViewDidMoveToWindow")
    }

    // Prevent the WebContent process from being throttled by App Nap while the
    // web view is not yet visible (e.g. during initial load with frame: .zero).
    if preferences.responds(to: sel_getUid("_setPageVisibilityBasedProcessSuppressionEnabled:")) {
      preferences.setValue(false, forKey: "pageVisibilityBasedProcessSuppressionEnabled")
    }

    // Prevent DOM timers from being throttled while the page is hidden,
    // which can otherwise slow down initialization JavaScript.
    if preferences.responds(to: sel_getUid("_setHiddenPageDOMTimerThrottlingEnabled:")) {
      preferences.setValue(false, forKey: "hiddenPageDOMTimerThrottlingEnabled")
    }

    // Prevent the throttle interval from automatically increasing the longer the page stays hidden.
    if preferences.responds(to: sel_getUid("_setHiddenPageDOMTimerThrottlingAutoIncreases:")) {
      preferences.setValue(false, forKey: "hiddenPageDOMTimerThrottlingAutoIncreases")
    }

    // Disable features with eager initialization cost at WebContent process startup
    // that serve no purpose in a local text editor.
    preferences.disableUnneededFeatures()
  }
}

// MARK: - Feature SPI

private extension WKPreferences {
  static var allFeatures: [AnyObject] {
    let selfClass = Self.self as AnyObject
    let selector = sel_getUid("_features")

    guard selfClass.responds(to: selector) else {
      return []
    }

    return (selfClass.perform(selector)?.takeUnretainedValue() as? [AnyObject]) ?? []
  }

  func disableUnneededFeatures() {
    // -[WKPreferences _setEnabled:forFeature:]
    let selector = sel_getUid(["_setEnabled:", "forFeature:"].joined())

    guard responds(to: selector) else {
      return
    }

    let keysToDisable: Set<String> = [
      // Background scripts for PWAs; requires a real HTTP server to register
      "ServiceWorkersEnabled",
      // W3C EME API for DRM-protected media playback
      "EncryptedMediaAPIEnabled",
      // Legacy (non-standard) DRM media playback API
      "LegacyEncryptedMediaAPIEnabled",
      // Cross-context mutex for coordinating shared storage across tabs/workers
      "WebLocksAPIEnabled",
    ]

    let setFeatureEnabled = unsafeBitCast(
      method(for: selector),
      to: (@convention(c) (NSObject, Selector, Bool, AnyObject) -> Void).self
    )

    for feature in WKPreferences.allFeatures {
      guard let key = feature.value(forKey: "key") as? String, keysToDisable.contains(key) else {
        continue
      }

      setFeatureEnabled(self, selector, false, feature)
    }
  }
}
