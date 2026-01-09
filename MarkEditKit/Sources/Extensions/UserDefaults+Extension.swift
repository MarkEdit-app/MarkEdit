//
//  UserDefaults+Extension.swift
//
//  Created by cyan on 12/17/22.
//

import Foundation

public let NSCloseAlwaysConfirmsChanges = "NSCloseAlwaysConfirmsChanges"
public let NSQuitAlwaysKeepsWindows = "NSQuitAlwaysKeepsWindows"
public let NSNavLastRootDirectory = "NSNavLastRootDirectory"

public extension UserDefaults {
  static func overwriteTextCheckerOnce() {
    let enabledFlag = "editor.overwrite-text-checker"
    guard !standard.bool(forKey: enabledFlag) else {
      return
    }

    // https://github.com/WebKit/WebKit/blob/main/Source/WebKit/UIProcess/mac/TextCheckerMac.mm
    let featureKeys = [
      // Features we enable once until user explicitly changes the setting
      "NSAllowContinuousSpellChecking",
      "WebAutomaticSpellingCorrectionEnabled",
      "WebContinuousSpellCheckingEnabled",
      "WebGrammarCheckingEnabled",
      "WebAutomaticLinkDetectionEnabled",
      "WebAutomaticTextReplacementEnabled",

      // Features that respect the system settings
      // "WebSmartInsertDeleteEnabled",
      // "WebAutomaticQuoteSubstitutionEnabled",
      // "WebAutomaticDashSubstitutionEnabled",
    ]

    featureKeys.forEach {
      standard.set(true, forKey: $0)
    }

    standard.set(true, forKey: enabledFlag)
  }

  static func resetTilingState(for key: String) {
    // E.g., "NSWindow Frame Editor" it's fine if we cannot find it
    guard let value = standard.string(forKey: key) else {
      return
    }

    // E.g., 0 135 1496 803 0 0 1496 938 {"tilingState":{"tilingPosition":9,"normalizedSize":...
    guard let range = value.range(of: " {\"tilingState\"") else {
      return
    }

    // E.g., 0 135 1496 803 0 0 1496 938
    standard.set(String(value.prefix(upTo: range.lowerBound)), forKey: key)
  }
}
