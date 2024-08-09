//
//  Application.swift
//  MarkEditMac
//
//  Created by cyan on 2024/4/24.
//

import AppKit

@main
final class Application: NSApplication {
  static func main() {
    NSObject.swizzleAccessibilityBundlesOnce
    NSSpellChecker.swizzleInlineCompletionEnabledOnce
    NSSpellChecker.swizzleShowCompletionForCandidateOnce
    NSSpellChecker.swizzleCorrectionIndicatorOnce

    let app = Self.shared
    let delegate = AppDelegate()

    app.delegate = delegate
    _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
  }

  override func sendAction(_ action: Selector, to target: Any?, from sender: Any?) -> Bool {
    if action == #selector(NSText.paste(_:)) {
      NSPasteboard.general.sanitize()
    }

    return super.sendAction(action, to: target, from: sender)
  }
}
