//
//  NSSpellChecker+Extension.swift
//  MarkEditMac
//
//  Created by cyan on 2/28/23.
//

import AppKit

extension NSSpellChecker {
  static func hasPanels() -> Bool {
    !spellCheckPanels.isEmpty
  }

  static func hidePanels() {
    spellCheckPanels.forEach { $0.alphaValue = 0 }
  }

  static func showPanels() {
    spellCheckPanels.forEach { $0.alphaValue = 1 }
  }

  func isMisspelled(word: String) -> Bool {
    checkSpelling(of: word, startingAt: 0).location != NSNotFound
  }
}

extension NSWindow {
  /// Returns true for the panel used for auto correction.
  var isSpellCheckPanel: Bool {
    // There's no public API to do that,
    // here we check if it's an NSPanel and it's probably a "NSCorrectionSubPanel" class.
    (self as? NSPanel)?.className.starts(with: "NSCorrectionSub") == true
  }
}

// MARK: - Private

private extension NSSpellChecker {
  static var spellCheckPanels: [NSWindow] {
    NSApp.windows.filter { $0.isSpellCheckPanel }
  }
}
