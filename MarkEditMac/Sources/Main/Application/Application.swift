//
//  Application.swift
//  MarkEditMac
//
//  Created by cyan on 4/24/24.
//

import AppKit
import ExtensionCore
import MarkEditKit

@main
final class Application: NSApplication {
  static func main() {
    if ApplicationEnvironment.isRunningTests {
      // XCTest needs NSApplicationMain, but not the app's startup services.
      AppCustomization.createFiles()
      _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
      return
    }

    NSObject.swizzleAccessibilityBundlesOnce
    NSApplication.swizzleCustomizeMainMenuOnce
    NSDocumentController.swizzleInstallOpenRecentMenusOnce
    NSMenu.swizzleIsUpdatedExcludingContentTypesOnce
    NSSpellChecker.swizzleInlineCompletionEnabledOnce
    NSSpellChecker.swizzleShowCompletionForCandidateOnce
    NSSpellChecker.swizzleCorrectionIndicatorOnce

    UserDefaults.overwriteTextCheckerOnce()
    AppCustomization.createFiles()

    // Scanning the scripts folder is slow, overlap it with AppKit initialization
    let reconciled = DispatchGroup()
    reconciled.enter()

    DispatchQueue.global(qos: .userInitiated).async {
      ExtensionConfig.reconcileInstalled()
      reconciled.leave()
    }

    let application = Self.shared
    let delegate = AppDelegate()

    application.delegate = delegate
    delegate.startAccessingBookmarks()

    reconciled.wait()
    _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
  }

  override func sendAction(_ action: Selector, to target: Any?, from sender: Any?) -> Bool {
    if action == #selector(NSText.paste(_:)) {
      sanitizePasteboard()
    }

    let handled = super.sendAction(action, to: target, from: sender)
    if handled && action == sel_getUid("toggleAutomaticQuoteSubstitution:") {
      AppPreferences.Editor.smartQuotesOptionToggled()
    }

    return handled
  }
}

enum ApplicationEnvironment {
  static let isRunningTests = NSClassFromString("XCTestCase") != nil
  static let testIdentifier = "app.markedit.tests.\(UUID().uuidString)"

  static var preferences: UserDefaults {
    guard isRunningTests else {
      return .standard
    }

    guard let preferences = UserDefaults(suiteName: testIdentifier) else {
      preconditionFailure("Unable to create isolated test preferences")
    }

    return preferences
  }

  static let documentsDirectory: URL = {
    guard isRunningTests else {
      return .documentsDirectory
    }

    let directory = FileManager.default.temporaryDirectory.appending(
      path: testIdentifier,
      directoryHint: .isDirectory
    )

    do {
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    } catch {
      preconditionFailure("Unable to create isolated test directory: \(error)")
    }

    return directory
  }()
}

// MARK: - Private

private extension Application {
  func sanitizePasteboard() {
    let textContent = currentEditor?.document?.stringValue
    let lineEndings = AppPreferences.General.defaultLineEndings.characters
    NSPasteboard.general.sanitize(lineBreak: textContent?.getLineBreak(defaultValue: lineEndings))
  }
}
