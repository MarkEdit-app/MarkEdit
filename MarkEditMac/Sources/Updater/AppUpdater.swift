//
//  AppUpdater.swift
//  MarkEditMac
//
//  Created by cyan on 11/1/23.
//

import AppKit
import MarkEditKit

enum AppUpdater {
  private enum Constants {
    static let api = "https://api.github.com/repos/MarkEdit-app/MarkEdit/releases/latest"
    static let decoder = {
      let decoder = JSONDecoder()
      decoder.keyDecodingStrategy = .convertFromSnakeCase
      return decoder
    }()
  }

  static func checkForUpdates(explicitly: Bool) async {
    guard let url = URL(string: Constants.api) else {
      return Logger.assertFail("Failed to create the URL: \(Constants.api)")
    }

    guard let (data, response) = try? await URLSession.shared.data(from: url) else {
      return Logger.log(.error, "Failed to reach out to the server")
    }

    guard let status = (response as? HTTPURLResponse)?.statusCode, status == 200 else {
      return Logger.log(.error, "Failed to get the update")
    }

    guard let version = try? Constants.decoder.decode(AppVersion.self, from: data) else {
      return Logger.log(.error, "Failed to decode the data")
    }

    DispatchQueue.onMainThread {
      presentUpdate(newVersion: version, explicitly: explicitly)
    }
  }
}

// MARK: - Private

private extension AppUpdater {
  static func presentUpdate(newVersion: AppVersion, explicitly: Bool) {
    guard let currentVersion = Bundle.main.shortVersionString else {
      return Logger.assertFail("Invalid current version string")
    }

    // Check if the new version was skipped
    guard explicitly || !AppPreferences.Updater.skippedVersions.contains(newVersion.name) else {
      return
    }

    // Check if the version is different and wasn't released to MAS
    guard newVersion.name != currentVersion && !newVersion.releasedToMAS else {
      return {
        guard explicitly else {
          return
        }

        let alert = NSAlert()
        alert.messageText = Localized.Updater.upToDateTitle
        alert.informativeText = String(format: Localized.Updater.upToDateMessage, currentVersion)
        alert.runModal()
      }()
    }

    let alert = NSAlert()
    alert.messageText = String(format: Localized.Updater.newVersionAvailable, newVersion.name)
    alert.informativeText = newVersion.body
    alert.addButton(withTitle: Localized.Updater.learnMore)

    if explicitly {
      alert.addButton(withTitle: Localized.Updater.notNow)
    } else {
      alert.addButton(withTitle: Localized.Updater.remindMeLater)
      alert.addButton(withTitle: Localized.Updater.skipThisVersion)
    }

    switch alert.runModal() {
    case .alertFirstButtonReturn: // Learn More
      if let url = URL(string: newVersion.htmlUrl) {
        NSWorkspace.shared.open(url)
      }
    case .alertThirdButtonReturn: // Skip This Version
      AppPreferences.Updater.skippedVersions = {
        var versions = Set(AppPreferences.Updater.skippedVersions)
        versions.insert(newVersion.name)
        return Array(versions)
      }()
    default:
      break
    }
  }
}
