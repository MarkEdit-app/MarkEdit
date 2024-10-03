//
//  UserDefaults+Extension.swift
//
//  Created by cyan on 12/17/22.
//

import Foundation

public let NSCloseAlwaysConfirmsChanges = "NSCloseAlwaysConfirmsChanges"
public let NSQuitAlwaysKeepsWindows = "NSQuitAlwaysKeepsWindows"

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
      standard.setValue(true, forKey: $0)
    }

    standard.setValue(true, forKey: enabledFlag)
  }
}
