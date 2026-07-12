//
//  ExtensionUpdater.swift
//  MarkEditMac
//
//  Created by cyan on 7/12/26.
//

import AppKit
import MarkEditKit

/// Checks the registry for newer extension releases and applies them per `registry.updateStrategy`.
@MainActor
enum ExtensionUpdater {
  /// An installed extension paired with its newer registry entry.
  struct Update {
    let installed: ExtensionConfig.Installed
    let entry: ExtensionEntry
  }

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

    let updates = availableUpdates(index: index)
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

  /// Installed extensions with a newer, compatible release in the registry.
  static func availableUpdates(index: ExtensionIndex) -> [Update] {
    ExtensionConfig.installed.compactMap { installed in
      // Only managed extensions with a pinned version participate
      guard let version = installed.version else {
        return nil
      }

      // Honor a per-extension "never" freeze
      guard installed.updateCheck != .never else {
        return nil
      }

      guard let entry = index.extensions.first(where: { $0.id == installed.id }) else {
        return nil
      }

      // Skip releases the current app can't run
      guard entry.latest.isCompatible else {
        return nil
      }

      // Skip older or equal versions
      guard entry.latest.version.compare(version, options: .numeric) == .orderedDescending else {
        return nil
      }

      return Update(installed: installed, entry: entry)
    }
  }
}

// MARK: - Private

private extension ExtensionUpdater {
  static func presentPrompt(updates: [Update]) async {
    let lines = updates.map {
      "• \($0.entry.name) (\($0.installed.version ?? "") → \($0.entry.latest.version))"
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

  static func apply(updates: [Update], promptRelaunch: Bool) async {
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
