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
    static let minimumDownloadDuration: TimeInterval = 2.5
    static let decoder = {
      let decoder = JSONDecoder()
      decoder.keyDecodingStrategy = .convertFromSnakeCase
      return decoder
    }()
  }

  @MainActor
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
          presentInstallError(Failure.downloadFailed)
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

    // A removed bad release may require returning to an older version
    let currentVersion = Bundle.main.shortVersionString
    Logger.assert(currentVersion != "1.0.0", "Invalid current version string")

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

  /// Shows release notes for an automatically staged update.
  @MainActor
  static func presentStagedUpdateNotes() {
    let version = AppPreferences.Updater.stagedUpdateVersion
    let notes = AppPreferences.Updater.stagedUpdateNotes
    AppPreferences.Updater.stagedUpdateVersion = nil
    AppPreferences.Updater.stagedUpdateNotes = nil

    let currentVersion = Bundle.main.shortVersionString
    if AppPreferences.Updater.unappliedUpdateVersion == currentVersion {
      AppPreferences.Updater.unappliedUpdateVersion = nil
    }

    guard let version else {
      return
    }

    guard version == currentVersion else {
      AppPreferences.Updater.unappliedUpdateVersion = version
      return
    }

    guard let notes else {
      return
    }

    presentReleaseNotes(version: version, body: notes)
  }
}

// MARK: - Private

private extension AppUpdater {
  @MainActor static var automatically: Bool {
    AppRuntimeConfig.updateBehavior != .never && !AppPreferences.Updater.completelyDisabled
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
  static func animatedDots(_ step: Int) -> String {
    // U+2008 is exactly as wide as a period
    let count = (step % 3) + 1
    return String(repeating: ".", count: count) + String(repeating: "\u{2008}", count: 3 - count)
  }

  static func menuItemImage(_ symbolName: String) -> NSImage? {
    AppDesign.menuIconEvolution ? NSImage(systemSymbolName: symbolName) : nil
  }

  static func makeUpdateAlert(newVersion: AppVersion, showingDetails: Bool = false) -> NSAlert {
    let alert = NSAlert()
    alert.messageText = String(
      format: showingDetails ? Localized.Updater.releaseNotesTitle : Localized.Updater.updateAvailableTitle,
      newVersion.name
    )

    return alert
  }

  static func presentUpdate(newVersion: AppVersion, releaseInfo: ReleaseInfo?, explicitly: Bool) {
    // E.g., currentOSVer = 14.7, minOSVer = 15.0, minOSVer is later than currentOSVer
    let currentOSVer = ProcessInfo.processInfo.semanticOSVer
    let minOSVer = releaseInfo?.minOSVer ?? Constants.defaultOSVer
    let needsOSUpdate = minOSVer.compare(currentOSVer, options: .numeric) == .orderedDescending

    if needsOSUpdate {
      presentOSUpdateAlert(newVersion: newVersion, minOSVer: minOSVer, explicitly: explicitly)
    } else {
      presentAppUpdateAlert(newVersion: newVersion, explicitly: explicitly)
    }
  }

  static func presentOSUpdateAlert(newVersion: AppVersion, minOSVer: String, explicitly: Bool) {
    let alert = makeUpdateAlert(newVersion: newVersion)
    alert.markdownBody = String(format: Localized.Updater.needsOSUpdateMessage, minOSVer)
    alert.addButton(withTitle: Localized.Updater.viewReleasePage)

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

  static func presentAppUpdateAlert(
    newVersion: AppVersion,
    explicitly: Bool,
    showingDetails: Bool = false
  ) {
    let canSelfUpdate = newVersion.isCompatible && newVersion.updateArchive != nil && canInstallInPlace

    // Avoid downloading an unapplied version again
    let wasUnapplied = AppPreferences.Updater.unappliedUpdateVersion == newVersion.name

    if !explicitly && AppRuntimeConfig.updateBehavior == .automatic && canSelfUpdate && !wasUnapplied {
      return stageAutomatically(newVersion: newVersion)
    }

    var actions = [(title: String, handler: () -> Void)]()
    if canSelfUpdate {
      actions.append((Localized.Updater.updateNow, { startUpdate(newVersion: newVersion) }))
    }

    actions.append((Localized.Updater.viewReleasePage, {
      NSWorkspace.shared.safelyOpenURL(string: newVersion.htmlUrl)
    }))

    if explicitly {
      actions.append((Localized.Updater.notNow, {}))
    } else {
      actions.append((Localized.Updater.remindMeLater, {}))
      actions.append((Localized.Updater.skipThisVersion, {
        AppPreferences.Updater.skippedVersions.insert(newVersion.name)
      }))
    }

    let alert = makeUpdateAlert(newVersion: newVersion, showingDetails: showingDetails)
    alert.markdownBody = newVersion.body

    let showAlert = {
      actions.forEach {
        alert.addButton(withTitle: $0.title)
      }

      let index = alert.runModal().rawValue - NSApplication.ModalResponse.alertFirstButtonReturn.rawValue
      if actions.indices.contains(index) {
        actions[index].handler()
      }

      clearStagedUpdateNotes(version: newVersion.name)
    }

    guard !explicitly && AppRuntimeConfig.updateBehavior != .notify, let delegate = NSApp.appDelegate else {
      return showAlert()
    }

    let mainUpdateItem = delegate.mainUpdateItem
    mainUpdateItem?.title = String(format: Localized.Updater.updateToMenuTitle, newVersion.name)
    mainUpdateItem?.isHidden = false

    // Reset controls repurposed for a staged update
    delegate.postponeUpdateItem?.title = Localized.Updater.remindMeLater
    delegate.postponeUpdateItem?.image = menuItemImage(Icons.bell)
    delegate.restartUpdateItem?.isHidden = true
    delegate.ignoreUpdateItem?.isHidden = false

    delegate.presentUpdateItem?.addAction("app.markedit.update-details") {
      presentAppUpdateAlert(newVersion: newVersion, explicitly: true, showingDetails: true)
    }

    delegate.postponeUpdateItem?.addAction("app.markedit.postpone-update") {
      mainUpdateItem?.isHidden = true
    }

    delegate.ignoreUpdateItem?.addAction("app.markedit.ignore-update") {
      mainUpdateItem?.isHidden = true
      AppPreferences.Updater.skippedVersions.insert(newVersion.name)
    }
  }

  static func presentReleaseNotes(version: String, body: String) {
    let alert = NSAlert()
    alert.messageText = String(format: Localized.Updater.releaseNotesTitle, version)
    alert.markdownBody = body
    alert.runModal()
    clearStagedUpdateNotes(version: version)
  }

  /// Stages an update silently for installation on quit.
  static func stageAutomatically(newVersion: AppVersion) {
    guard AppPreferences.Updater.stagedUpdateVersion != newVersion.name, reserveStaging() else {
      return
    }

    Task {
      do {
        try await stageUpdate(newVersion: newVersion)
        AppPreferences.Updater.stagedUpdateVersion = newVersion.name
        AppPreferences.Updater.stagedUpdateNotes = newVersion.body
        revealStagedUpdate(newVersion: newVersion)
      } catch {
        Logger.log(.error, "Failed to stage the update: \(error.localizedDescription)")
      }
    }
  }

  static func startUpdate(newVersion: AppVersion) {
    guard reserveStaging() else {
      return
    }

    let updateItem = NSApp.appDelegate?.mainUpdateItem
    let wasVisible = updateItem?.isHidden == false
    updateItem?.isHidden = false

    let animation = Task {
      var step = 0
      while !Task.isCancelled {
        updateItem?.title = String(format: Localized.Updater.downloadingMenuTitle, animatedDots(step))
        step += 1
        try? await Task.sleep(for: .milliseconds(300))
      }
    }

    Task {
      let started = Date()

      do {
        try await stageUpdate(newVersion: newVersion)

        // Keep progress visible briefly
        let remaining = Constants.minimumDownloadDuration - Date().timeIntervalSince(started)
        if remaining > 0 {
          try? await Task.sleep(for: .seconds(remaining))
        }

        // Prevent the alert from racing the animation
        animation.cancel()
        presentRestartAlert(newVersion: newVersion)
      } catch {
        animation.cancel()
        updateItem?.isHidden = !wasVisible
        updateItem?.title = String(format: Localized.Updater.updateToMenuTitle, newVersion.name)
        presentInstallError(error, releaseURL: newVersion.htmlUrl)
      }
    }
  }

  /// Shows a staged update in the update menu.
  static func revealStagedUpdate(newVersion: AppVersion) {
    guard let delegate = NSApp.appDelegate else {
      return
    }

    let mainUpdateItem = delegate.mainUpdateItem
    mainUpdateItem?.title = String(format: Localized.Updater.updateReadyMenuTitle, newVersion.name)
    mainUpdateItem?.isHidden = false

    delegate.restartUpdateItem?.title = Localized.Updater.restartNow
    delegate.restartUpdateItem?.image = menuItemImage(Icons.restart)
    delegate.restartUpdateItem?.isHidden = false
    delegate.restartUpdateItem?.addAction("app.markedit.restart-update") {
      restartToUpdate()
    }

    // Keep release notes available after dismissing the alert
    delegate.presentUpdateItem?.addAction("app.markedit.update-details") {
      presentReleaseNotes(version: newVersion.name, body: newVersion.body)
    }

    // A staged update installs on quit regardless
    delegate.ignoreUpdateItem?.isHidden = true

    // Hiding the menu doesn't cancel installation
    delegate.postponeUpdateItem?.title = Localized.Updater.installOnQuit
    delegate.postponeUpdateItem?.image = menuItemImage(Icons.clock)
    delegate.postponeUpdateItem?.addAction("app.markedit.postpone-update") {
      mainUpdateItem?.isHidden = true
    }
  }

  static func presentRestartAlert(newVersion: AppVersion) {
    // Keep the staged update accessible if restart is declined
    revealStagedUpdate(newVersion: newVersion)

    let alert = NSAlert()
    alert.messageText = String(format: Localized.Updater.updateReadyTitle, newVersion.name)
    alert.informativeText = Localized.Updater.updateReadyMessage
    alert.addButton(withTitle: Localized.Updater.restartNow)
    alert.addButton(withTitle: Localized.Updater.installOnQuit)

    if alert.runModal() == .alertFirstButtonReturn {
      restartToUpdate()
    }
  }

  static func restartToUpdate() {
    NSApp.relaunchSafely()
  }

  static func clearStagedUpdateNotes(version: String) {
    if AppPreferences.Updater.stagedUpdateVersion == version {
      AppPreferences.Updater.stagedUpdateNotes = nil
    }
  }
}
