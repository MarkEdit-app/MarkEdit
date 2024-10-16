//
//  Application.swift
//  MarkEditMac
//
//  Created by cyan on 2024/4/24.
//

import AppKit
import MarkEditKit

@main
final class Application: NSApplication {
  static func main() {
    NSObject.swizzleAccessibilityBundlesOnce
    NSSpellChecker.swizzleInlineCompletionEnabledOnce
    NSSpellChecker.swizzleShowCompletionForCandidateOnce
    NSSpellChecker.swizzleCorrectionIndicatorOnce
    UserDefaults.overwriteTextCheckerOnce()
    AppCustomization.createFiles()

    let application = Self.shared
    let delegate = AppDelegate()

    application.delegate = delegate
    delegate.startAccessingGrantedFolder()

    _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
  }

  override func sendAction(_ action: Selector, to target: Any?, from sender: Any?) -> Bool {
    if action == #selector(NSText.paste(_:)) {
      NSPasteboard.general.sanitize()
    }

    // Ensure lines are fully selected for a better WritingTools experience
    if action == sel_getUid("showWritingTools:") {
      Logger.assert(sender is NSMenuItem, "Invalid sender was found")
      Logger.assert((target as? AnyObject)?.className == "WKMenuTarget", "Invalid target was found")
      ensureWritingToolsSelectionRect()

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        super.sendAction(action, to: target, from: sender)
      }

      return true
    }

    return super.sendAction(action, to: target, from: sender)
  }
}

// MARK: - Private

private extension Application {
  func ensureWritingToolsSelectionRect() {
    guard let editor = NSApp.mainWindow?.contentViewController as? EditorViewController else {
      return Logger.assertFail("Invalid mainWindow was found")
    }

    editor.ensureWritingToolsSelectionRect()
  }
}
