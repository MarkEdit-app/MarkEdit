//
//  ExtensionUpdater.swift
//  MarkEditMac
//
//  Created by cyan on 7/12/26.
//

import AppKit
import ExtensionCore
import MarkEditKit

extension Notification.Name {
  /// Posted when the extension registry index or installed extensions change.
  static let extensionsDidChange = Self("app.cyan.markedit.extensionsDidChange")
}

/// Checks the registry for newer extension releases and applies them per `registry.updateStrategy`.
@MainActor
enum ExtensionUpdater {
  /// Refreshes the index promptly and prompts about updates on the configured cadence.
  ///
  /// - Parameter explicitly: force a refresh and bypass the prompt cadence.
  static func checkForUpdates(explicitly: Bool = false) async {
    // Refresh cache first; nil means no usable index.
    guard let index = await ExtensionRegistry.refresh(force: explicitly) else {
      return
    }

    // A refreshed index may change what's outdated, let app-level UI (the menu-bar hint) refresh.
    NotificationCenter.default.post(name: .extensionsDidChange, object: nil)

    // Prompt cadence is tracked separately.
    guard explicitly || ExtensionRegistry.shouldPromptUpdates else {
      return
    }

    let updates = ExtensionRegistry.availableUpdates(index: index)
    guard !updates.isEmpty else {
      return
    }

    // Only advance the prompt cadence when something is actually surfaced.
    switch ExtensionConfig.updateStrategy {
    case .manual:
      break // Surfaced only in the Extensions window
    case .prompt:
      ExtensionRegistry.recordUpdatePrompt()
      await presentPrompt(updates: updates)
    case .automatic:
      ExtensionRegistry.recordUpdatePrompt()
      await apply(updates: updates, promptRelaunch: false)
    }
  }
}

// MARK: - Private

private extension ExtensionUpdater {
  static func presentPrompt(updates: [ExtensionUpdate]) async {
    let lines = updates.map { update in
      "• \(update.entry.name) (\(update.installed.version ?? "?") → \(update.entry.latest.version))"
    }

    let alert = NSAlert()
    alert.messageText = Localized.Extension.updatesAvailableTitle
    alert.informativeText = lines.joined(separator: "\n")
    alert.addButton(withTitle: Localized.Extension.updateButton)
    alert.addButton(withTitle: Localized.Extension.laterButton)

    guard alert.runModal() == .alertFirstButtonReturn else {
      return
    }

    let failures = await apply(updates: updates, promptRelaunch: true)
    if !failures.isEmpty {
      presentFailure(failures)
    }
  }

  /// Downloads and persists each update, returning the ones that failed.
  @discardableResult
  static func apply(updates: [ExtensionUpdate], promptRelaunch: Bool) async -> [(name: String, error: Error)] {
    var didUpdate = false
    var failures: [(name: String, error: Error)] = []

    for update in updates {
      do {
        // Preserve previous enabled state and cadence.
        let merged = try await ExtensionDownloader.downloadUpdate(
          for: update.installed,
          entry: update.entry
        )

        ExtensionConfig.upsertInstalled(merged)
        didUpdate = true
      } catch {
        failures.append((update.entry.name, error))
        Logger.log(.error, "Failed to install extension \(update.entry.id): \(error)")
      }
    }

    if didUpdate && promptRelaunch {
      presentRelaunch()
    }

    return failures
  }

  static func presentFailure(_ failures: [(name: String, error: Error)]) {
    let alert = NSAlert()
    alert.messageText = Localized.Extension.failedTitle
    alert.informativeText = failures
      .map { "• \($0.name) - \(failureReason($0.error))" }
      .joined(separator: "\n")
    alert.runModal()
  }

  /// A user-facing reason for a failed install, mirroring the single-install path.
  static func failureReason(_ error: Error) -> String {
    if case ExtensionDownloader.Failure.incompatible(let minAppVersion) = error {
      return String(format: Localized.Extension.incompatibleFormat, minAppVersion)
    }

    return Localized.Extension.failedMessage
  }

  static func presentRelaunch() {
    let alert = NSAlert()
    alert.messageText = Localized.Extension.updatedTitle
    alert.informativeText = Localized.Extension.updatedMessage
    alert.addButton(withTitle: Localized.Extension.relaunchButton)
    alert.addButton(withTitle: Localized.Extension.laterButton)

    if alert.runModal() == .alertFirstButtonReturn {
      NSWorkspace.shared.relaunchApp()
    }
  }
}
