//
//  AppUpdater.swift
//  MarkEditMac
//
//  Created by cyan on 11/1/23.
//

import AppKit
import AppKitExtensions
import MarkEditKit

enum AppUpdater {
  private enum Constants {
    static let defaultOSVer = "1.0.0"
    static let endpoint = "https://api.github.com/repos/MarkEdit-app/MarkEdit/releases/latest"
    static let decoder = {
      let decoder = JSONDecoder()
      decoder.keyDecodingStrategy = .convertFromSnakeCase
      return decoder
    }()
  }

  static func checkForUpdates(explicitly: Bool, skippedVersions: Set<String>) async {
    guard explicitly || automatically else {
      return Logger.log(.info, "App update checks have been skipped")
    }

    guard let url = URL(string: Constants.endpoint) else {
      return Logger.assertFail("Failed to create the URL: \(Constants.endpoint)")
    }

    guard let (data, response) = try? await URLSession.shared.data(from: url) else {
      return Logger.log(.error, "Failed to reach out to the server")
    }

    guard let status = (response as? HTTPURLResponse)?.statusCode, status == 200 else {
      if explicitly {
        DispatchQueue.main.async {
          presentError()
        }
      }

      return Logger.log(.error, "Failed to get the update")
    }

    guard let version = try? Constants.decoder.decode(AppVersion.self, from: data) else {
      return Logger.log(.error, "Failed to decode the data")
    }

    // Check if the new version was skipped for implicit updates
    guard explicitly || !skippedVersions.contains(version.name) else {
      return
    }

    // Check if the version is different and wasn't released to MAS
    let currentVersion = Bundle.main.shortVersionString ?? "0.0.0"
    Logger.assert(currentVersion != "0.0.0", "Invalid current version string")

    guard version.name != currentVersion && !version.releasedToMAS else {
      return {
        guard explicitly else {
          return
        }

        DispatchQueue.main.async {
          let alert = NSAlert()
          alert.messageText = Localized.Updater.upToDateTitle
          alert.informativeText = String(format: Localized.Updater.upToDateMessage, currentVersion)
          alert.runModal()
        }
      }()
    }

    let releaseInfo = await extractReleaseInfo(from: version)
    Logger.log(.info, "v\(version.name) needs macOS \(releaseInfo?.minOSVer ?? Constants.defaultOSVer)")

    DispatchQueue.main.async {
      presentUpdate(newVersion: version, releaseInfo: releaseInfo, explicitly: explicitly)
    }
  }
}

// MARK: - Private

private extension AppUpdater {
  static var automatically: Bool {
    // Can be disabled through either settings.json or an incompatible update
    AppRuntimeConfig.checksForUpdates && !AppPreferences.Updater.completelyDisabled
  }

  static func extractReleaseInfo(from version: AppVersion) async -> ReleaseInfo? {
    guard let info = (version.assets?.first { $0.name == "ReleaseInfo.json" }) else {
      Logger.log(.error, "Missing ReleaseInfo.json")
      return nil
    }

    guard let url = URL(string: info.browserDownloadUrl) else {
      Logger.log(.error, "Invalid asset url: \(info.browserDownloadUrl)")
      return nil
    }

    guard let (data, _) = try? await URLSession.shared.data(from: url) else {
      Logger.log(.error, "Failed to reach out to the server")
      return nil
    }

    guard let info = try? Constants.decoder.decode(ReleaseInfo.self, from: data) else {
      Logger.log(.error, "Failed to decode the data")
      return nil
    }

    return info
  }
}

@MainActor
private extension AppUpdater {
  static func presentError() {
    let alert = NSAlert()
    alert.messageText = Localized.Updater.updateFailedTitle
    alert.informativeText = Localized.Updater.updateFailedMessage
    alert.addButton(withTitle: Localized.Updater.checkVersionHistory)
    alert.addButton(withTitle: Localized.Updater.notNow)

    if alert.runModal() == .alertFirstButtonReturn {
      NSWorkspace.shared.safelyOpenURL(string: "https://github.com/MarkEdit-app/MarkEdit/releases")
    }
  }

  static func presentUpdate(newVersion: AppVersion, releaseInfo: ReleaseInfo?, explicitly: Bool) {
    // E.g., currentOSVer = 14.7, minOSVer = 15.0, minOSVer is later than currentOSVer
    let currentOSVer = ProcessInfo.processInfo.semanticOSVer
    let minOSVer = releaseInfo?.minOSVer ?? Constants.defaultOSVer
    let needsOSUpdate = minOSVer.compare(currentOSVer, options: .numeric) == .orderedDescending

    let alert = NSAlert()
    alert.messageText = String(format: Localized.Updater.newVersionAvailable, newVersion.name)
    alert.addButton(withTitle: Localized.Updater.viewReleasePage)

    if needsOSUpdate {
      presentOSUpdateAlert(alert, newVersion: newVersion, minOSVer: minOSVer, explicitly: explicitly)
    } else {
      presentAppUpdateAlert(alert, newVersion: newVersion, explicitly: explicitly)
    }
  }

  static func presentOSUpdateAlert(
    _ alert: NSAlert,
    newVersion: AppVersion,
    minOSVer: String,
    explicitly: Bool
  ) {
    alert.markdownBody = String(format: Localized.Updater.needsOSUpdateMessage, minOSVer)
    if explicitly {
      alert.addButton(withTitle: Localized.Updater.notNow)
    } else {
      alert.addButton(withTitle: Localized.Updater.skipThisVersion)
      alert.addButton(withTitle: Localized.Updater.disableUpdateChecks)
    }

    switch alert.runModal() {
    case .alertFirstButtonReturn: // View Release Page
      NSWorkspace.shared.safelyOpenURL(string: newVersion.htmlUrl)
    case .alertSecondButtonReturn:
      if explicitly {
        // no-op for "Not Now"
      } else {
        // Skip This Version
        AppPreferences.Updater.skippedVersions.insert(newVersion.name)
      }
    case .alertThirdButtonReturn: // Disable Update Checks
      AppPreferences.Updater.completelyDisabled = true
    default:
      break
    }
  }

  @MainActor
  static func presentAppUpdateAlert(_ alert: NSAlert, newVersion: AppVersion, explicitly: Bool) {
    alert.markdownBody = newVersion.body
    if explicitly {
      alert.addButton(withTitle: Localized.Updater.notNow)
    } else {
      alert.addButton(withTitle: Localized.Updater.remindMeLater)
      alert.addButton(withTitle: Localized.Updater.skipThisVersion)
    }

    switch alert.runModal() {
    case .alertFirstButtonReturn: // View Release Page
      NSWorkspace.shared.safelyOpenURL(string: newVersion.htmlUrl)
    case .alertThirdButtonReturn: // Skip This Version
      AppPreferences.Updater.skippedVersions.insert(newVersion.name)
    default:
      break
    }
  }
}
