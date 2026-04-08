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
    if !setBoolValue(false, forSelector: "_setDelaysWebProcessLaunchUntilFirstLoad:") {
      assertionFailure("Failed to call _setDelaysWebProcessLaunchUntilFirstLoad:")
    }

    // Skip the blocking wait for the first rendered frame after the view joins a window.
    //
    // The default behavior synchronizes the first paint, which is unnecessary here
    // since the background color is already transparent (_drawsBackground returns false).
    if !setBoolValue(false, forSelector: "_setWaitsForPaintAfterViewDidMoveToWindow:") {
      assertionFailure("Failed to call _setWaitsForPaintAfterViewDidMoveToWindow:")
    }

    // Prevent the WebContent process from being throttled by App Nap while the
    // web view is not yet visible (e.g. during initial load with frame: .zero).
    if !preferences.setBoolValue(false, forSelector: "_setPageVisibilityBasedProcessSuppressionEnabled:") {
      assertionFailure("Failed to call _setPageVisibilityBasedProcessSuppressionEnabled:")
    }

    // Prevent DOM timers from being throttled while the page is hidden,
    // which can otherwise slow down initialization JavaScript.
    if !preferences.setBoolValue(false, forSelector: "_setHiddenPageDOMTimerThrottlingEnabled:") {
      assertionFailure("Failed to call _setHiddenPageDOMTimerThrottlingEnabled:")
    }

    // Prevent the throttle interval from automatically increasing the longer the page stays hidden.
    if !preferences.setBoolValue(false, forSelector: "_setHiddenPageDOMTimerThrottlingAutoIncreases:") {
      assertionFailure("Failed to call _setHiddenPageDOMTimerThrottlingAutoIncreases:")
    }

    // Disable features with eager initialization cost at WebContent process startup
    // that serve no purpose in a local text editor.
    preferences.disableUnneededFeatures()
  }
}

// MARK: - WebKitConfigSPI

public protocol WebKitConfigSPI: NSObject {}
extension WKWebViewConfiguration: WebKitConfigSPI {}
extension WKPreferences: WebKitConfigSPI {}

public extension WebKitConfigSPI {
  @discardableResult
  func setBoolValue(_ value: Bool, forSelector selectorName: String) -> Bool {
    let selector = sel_getUid(selectorName)
    guard responds(to: selector) else {
      return false
    }

    let setValue = unsafeBitCast(
      method(for: selector),
      to: (@convention(c) (NSObject, Selector, Bool) -> Void).self
    )

    setValue(self, selector, value)
    return true
  }
}

// MARK: - Feature SPI

private extension WKPreferences {
  static var allFeatures: [AnyObject] {
    let selfClass = WKPreferences.self as AnyObject
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
      assertionFailure("Failed to find _setEnabled:forFeature:")
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
