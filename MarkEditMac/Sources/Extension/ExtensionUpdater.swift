//
//  ExtensionUpdater.swift
//  MarkEditMac
//
//  Created by cyan on 7/12/26.
//

import AppKit
import ExtensionKit
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
      let latest = update.entry.latest.version
      // A version-less install is being adopted, so there's no "from" to show
      if let current = update.installed.version {
        return "• \(update.entry.name) (\(current) → \(latest))"
      } else {
        return "• \(update.entry.name) (\(latest))"
      }
    }

    let alert = NSAlert()
    alert.messageText = Localized.Extension.updatesAvailableTitle
    alert.informativeText = lines.joined(separator: "\n")
    alert.addButton(withTitle: Localized.Extension.updateButton)
    alert.addButton(withTitle: Localized.Extension.laterButton)

    guard alert.runModal() == .alertFirstButtonReturn else {
      return
    }

    await apply(updates: updates, promptRelaunch: true)
  }

  static func apply(updates: [ExtensionUpdate], promptRelaunch: Bool) async {
    var didUpdate = false
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
        Logger.log(.error, "Failed to update extension \(update.entry.id): \(error)")
      }
    }

    if didUpdate && promptRelaunch {
      presentRelaunch()
    }
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
