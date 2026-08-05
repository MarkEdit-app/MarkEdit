//
//  AppUpdater+Install.swift
//  MarkEditMac
//
//  Created by cyan on 8/2/26.
//

import AppKit
import MarkEditKit

/**
 Sandboxed app side of the self-updater.
 */
@MainActor
extension AppUpdater {
  private(set) static var isStaging = false

  static var canInstallInPlace: Bool {
    let bundleURL = Bundle.main.bundleURL
    guard !bundleURL.path(percentEncoded: false).contains("/AppTranslocation/") else {
      return false
    }

    let values = try? bundleURL.resourceValues(forKeys: [.volumeIsReadOnlyKey])
    return values?.volumeIsReadOnly != true
  }

  /// Downloads, extracts, and verifies an update.
  static func stageUpdate(newVersion: AppVersion) async throws {
    guard let asset = newVersion.updateArchive else {
      throw Failure.missingAsset
    }

    isStaging = true
    defer { isStaging = false }

    // Replace any previously staged update
    await discardStagedUpdate()

    let archive = try await download(asset)
    defer { try? FileManager.default.removeItem(at: archive) }

    let staged = try await prepareUpdate(archivePath: archive.path(percentEncoded: false))
    AppPreferences.Updater.stagedUpdatePath = staged
  }

  /// Hands the staged update to the installer during termination.
  static func commitStagedUpdate() {
    guard let stagedPath = AppPreferences.Updater.stagedUpdatePath else {
      AppRelauncher.scheduleIfRequested()
      return
    }

    let connection = makeConnection()
    defer { connection.invalidate() }

    let shouldRelaunch = AppRelauncher.isRequested
    let recoverFromFailure = {
      if shouldRelaunch {
        AppRelauncher.scheduleIfRequested()
      }
    }

    let proxy = connection.synchronousRemoteObjectProxyWithErrorHandler { error in
      Logger.log(.error, "Failed to reach the update installer: \(error.localizedDescription)")
      recoverFromFailure()
    } as? UpdateInstalling

    guard let proxy else {
      return recoverFromFailure()
    }

    proxy.commitUpdate(
      stagedPath: stagedPath,
      processIdentifier: ProcessInfo.processInfo.processIdentifier,
      relaunch: shouldRelaunch
    ) { error in
      if let error {
        Logger.log(.error, "Failed to start the update installer: \(error)")
        return recoverFromFailure()
      }

      // The installer now owns the staged copy
      AppPreferences.Updater.stagedUpdatePath = nil
    }
  }

  /// Deletes a staged update that was never handed over to the installer.
  static func discardStagedUpdate() async {
    guard let stagedPath = AppPreferences.Updater.stagedUpdatePath else {
      return
    }

    AppPreferences.Updater.stagedUpdatePath = nil
    let connection = makeConnection()
    defer { connection.invalidate() }

    do {
      try await (connection.remoteObjectProxy as? UpdateInstalling)?.discardUpdate(stagedPath: stagedPath)
    } catch {
      Logger.log(.error, "Failed to discard the staged update: \(error.localizedDescription)")
    }
  }

  /// - Parameter releaseURL: page for the release that failed, falls back to the full version history.
  static func presentInstallError(_ error: any Error, releaseURL: String? = nil) {
    Logger.log(.error, "Failed to update: \(error.localizedDescription)")
    let failure = error as? Failure
    let alert = NSAlert()
    alert.messageText = failure?.title ?? Localized.Updater.installFailedTitle
    alert.informativeText = failure?.localizedDescription ?? Localized.Updater.installFailedMessage
    alert.addButton(withTitle: releaseURL == nil ? Localized.Updater.checkVersionHistory : Localized.Updater.viewReleasePage)
    alert.addButton(withTitle: Localized.Updater.notNow)

    if alert.runModal() == .alertFirstButtonReturn {
      NSWorkspace.shared.safelyOpenURL(string: releaseURL ?? "https://github.com/MarkEdit-app/MarkEdit/releases")
    }
  }
}

// MARK: - Shared

extension AppUpdater {
  enum Failure: LocalizedError {
    case missingAsset
    case downloadFailed
    case serviceUnavailable
    case serviceFailed(String)

    var title: String {
      switch self {
      case .missingAsset, .downloadFailed:
        return Localized.Updater.updateFailedTitle
      case .serviceUnavailable, .serviceFailed:
        return Localized.Updater.installFailedTitle
      }
    }

    var errorDescription: String? {
      switch self {
      case .missingAsset, .downloadFailed:
        return Localized.Updater.updateFailedMessage
      case .serviceUnavailable:
        return Localized.Updater.installFailedMessage
      case .serviceFailed(let reason):
        return reason
      }
    }
  }
}

// MARK: - Private

@MainActor
private extension AppUpdater {
  static var serviceName: String {
    "\(Bundle.main.bundleIdentifier ?? "app.cyan.markedit").installer"
  }

  static func makeConnection() -> NSXPCConnection {
    let connection = NSXPCConnection(serviceName: serviceName)
    connection.remoteObjectInterface = NSXPCInterface(with: UpdateInstalling.self)
    connection.resume()

    return connection
  }

  static func prepareUpdate(archivePath: String) async throws -> String {
    let connection = makeConnection()
    defer { connection.invalidate() }

    guard let proxy = connection.remoteObjectProxy as? UpdateInstalling else {
      throw Failure.serviceUnavailable
    }

    do {
      return try await proxy.prepareUpdate(archivePath: archivePath)
    } catch let error as NSError where error.domain == NSCocoaErrorDomain {
      // Treat transport errors separately from service failures
      Logger.log(.error, "Failed to reach the update installer: \(error.localizedDescription)")
      throw Failure.serviceUnavailable
    } catch {
      throw Failure.serviceFailed(error.localizedDescription)
    }
  }
}
