//
//  ExtensionUpdater.swift
//  MarkEditMac
//
//  Created by cyan on 7/12/26.
//

import AppKit
import ExtensionCore
import MarkEditKit

/// Checks the registry for newer extension releases and applies them per `registry.updateStrategy`.
@MainActor
enum ExtensionUpdater {
  /// Refreshes the index on the configured cadence and acts on any available updates.
  ///
  /// - Parameter explicitly: bypass the cadence, e.g. a manual "Check for Updates".
  static func checkForUpdates(explicitly: Bool = false) async {
    guard explicitly || ExtensionRegistry.isCheckDue else {
      return
    }

    guard let index = await ExtensionRegistry.refresh(force: explicitly) else {
      return
    }

    let updates = ExtensionRegistry.availableUpdates(index: index)
    guard !updates.isEmpty else {
      return
    }

    switch ExtensionConfig.updateStrategy {
    case .manual:
      break // Surfaced only in the manager UI
    case .prompt:
      await presentPrompt(updates: updates)
    case .automatic:
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
        let record = try await ExtensionDownloader.install(
          id: update.entry.id,
          release: update.entry.latest
        )

        // Keep the previous enabled state and per-extension cadence
        let merged = record.merging(preserving: update.installed)
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
