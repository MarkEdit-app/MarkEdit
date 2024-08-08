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

  static func activateMainWindow() {
    NSApp.activate(ignoringOtherApps: true)

    // Order out immaterial windows like settings, about...
    for window in NSApp.windows where !(window is EditorWindow) {
      window.orderOut(nil)
    }

    // Ensure at least one editor window is key and ordered front
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      let windows = NSApp.windows.filter { $0 is EditorWindow }
      if windows.allSatisfy({ !$0.isKeyWindow }) {
        windows.first?.makeKeyAndOrderFront(nil)
      }
    }
  }

  override func sendAction(_ action: Selector, to target: Any?, from sender: Any?) -> Bool {
    if action == #selector(NSText.paste(_:)) {
      NSPasteboard.general.sanitize()
    }

    return super.sendAction(action, to: target, from: sender)
  }
}
