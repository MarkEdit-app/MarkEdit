//
//  Application.swift
//  MarkEditMac
//
//  Created by cyan on 4/24/24.
//

import AppKit
import MarkEditKit

@main
final class Application: NSApplication {
  var currentEditor: EditorViewController? {
    keyWindow?.contentViewController as? EditorViewController
  }

  static func main() {
    NSObject.swizzleAccessibilityBundlesOnce
    NSMenu.swizzleIsUpdatedExcludingContentTypesOnce
    NSSpellChecker.swizzleInlineCompletionEnabledOnce
    NSSpellChecker.swizzleShowCompletionForCandidateOnce
    NSSpellChecker.swizzleCorrectionIndicatorOnce

    UserDefaults.overwriteTextCheckerOnce()
    AppCustomization.createFiles()

    // Must after AppCustomization.createFiles()
    Bundle.swizzleInfoDictionaryOnce

    let application = Self.shared
    let delegate = AppDelegate()

    application.delegate = delegate
    delegate.startAccessingGrantedFolder()

    _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
  }

  override func sendAction(_ action: Selector, to target: Any?, from sender: Any?) -> Bool {
    if action == #selector(NSText.paste(_:)) {
      sanitizePasteboard()
    }

    // Ensure lines are fully selected for a better Writing Tools experience
    if #available(macOS 15.1, *), action == sel_getUid("showWritingTools:") {
      Logger.assert(sender is NSMenuItem, "Invalid sender was found")
      Logger.assert(target == nil || (target as? AnyObject)?.className == "WKMenuTarget", "Invalid target was found")

      if MarkEditWritingTools.shouldReselect(withItem: sender) {
        ensureWritingToolsSelectionRect()
      }

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
  func sanitizePasteboard() {
    let textContent = currentEditor?.document?.stringValue
    let lineEndings = AppPreferences.General.defaultLineEndings.characters
    NSPasteboard.general.sanitize(lineBreak: textContent?.getLineBreak(defaultValue: lineEndings))
  }

  func ensureWritingToolsSelectionRect() {
    guard let currentEditor else {
      return Logger.assertFail("Invalid keyWindow was found")
    }

    currentEditor.ensureWritingToolsSelectionRect()
  }
}
