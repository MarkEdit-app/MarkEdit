//
//  ExtensionInstaller.swift
//  MarkEditMac
//
//  Created by cyan on 7/11/26.
//

import AppKit
import ExtensionCore
import MarkEditKit

/// Handles `markedit://install-extension` deep links.
///
/// `?id=` resolves against the reviewed registry, `?url=` is an unreviewed manual install.
/// Both always confirm with the user, verify or pin the sha256, and offer a relaunch so the
/// newly installed script is injected. Never a silent install.
@MainActor
enum ExtensionInstaller {
  static func install(queryDict: [String: String]?) {
    if let id = queryDict?["id"], !id.isEmpty {
      Task {
        await installFromRegistry(id: id)
      }
    } else if let string = queryDict?["url"], let url = URL(string: string) {
      installFromURL(url)
    } else {
      Logger.log(.error, "Invalid install-extension deep link")
    }
  }
}

// MARK: - Private

private extension ExtensionInstaller {
  static func installFromRegistry(id: String) async {
    guard let entry = await resolveEntry(id: id) else {
      presentError(message: String(format: Localized.Extension.notFoundFormat, id))
      return
    }

    let confirmed = confirm(
      name: entry.name,
      author: entry.author,
      source: entry.latest.url,
      unreviewed: false
    )

    guard confirmed else {
      return
    }

    await completeInstall {
      try await ExtensionDownloader.install(entry: entry)
    }
  }

  static func installFromURL(_ url: URL) {
    let confirmed = confirm(
      name: url.deletingPathExtension().lastPathComponent,
      author: nil,
      source: url.absoluteString,
      unreviewed: true
    )

    guard confirmed else {
      return
    }

    Task {
      await completeInstall {
        try await ExtensionDownloader.install(url: url)
      }
    }
  }

  /// Looks up the id in the cached index, forcing a fresh fetch before giving up.
  static func resolveEntry(id: String) async -> ExtensionEntry? {
    if let entry = ExtensionRegistry.cachedIndex?.extensions.first(where: { $0.id == id }) {
      return entry
    }

    return await ExtensionRegistry.refresh(force: true)?.extensions.first { $0.id == id }
  }

  /// Runs the download, persists the resulting record, and presents the outcome.
  static func completeInstall(_ download: () async throws -> ExtensionConfig.Installed) async {
    do {
      let installed = try await download()
      ExtensionConfig.upsertInstalled(installed)
      presentInstalled(id: installed.id)
    } catch ExtensionDownloader.Failure.incompatible(let minAppVersion) {
      presentError(message: String(format: Localized.Extension.incompatibleFormat, minAppVersion))
    } catch {
      Logger.log(.error, "Failed to install extension: \(error)")
      presentError(message: Localized.Extension.failedMessage)
    }
  }

  static func confirm(name: String, author: String?, source: String, unreviewed: Bool) -> Bool {
    var lines = [String]()
    if let author {
      lines.append(String(format: Localized.Extension.authorFormat, author))
    }

    lines.append(String(format: Localized.Extension.urlFormat, "[\(source.truncatedForDisplay())](<\(source)>)"))
    lines.append("_\(Localized.Extension.fullAccessWarning)_")

    if unreviewed {
      lines.append("_\(Localized.Extension.unreviewedWarning)_")
    }

    let alert = NSAlert()
    alert.messageText = String(format: Localized.Extension.confirmTitleFormat, name)
    alert.markdownBody = lines.joined(separator: "\n\n")
    alert.addButton(withTitle: Localized.Extension.installButton)
    alert.addButton(withTitle: Localized.General.cancel)

    let response = alert.runModal() == .alertFirstButtonReturn
    return response
  }

  static func presentInstalled(id: String) {
    let alert = NSAlert()
    alert.messageText = Localized.Extension.installedTitle
    alert.informativeText = String(format: Localized.Extension.installedMessageFormat, id)
    alert.addButton(withTitle: Localized.Extension.relaunchButton)
    alert.addButton(withTitle: Localized.Extension.laterButton)

    if alert.runModal() == .alertFirstButtonReturn {
      NSWorkspace.shared.relaunchApp()
    }
  }

  static func presentError(message: String) {
    let alert = NSAlert()
    alert.messageText = Localized.Extension.failedTitle
    alert.informativeText = message
    alert.runModal()
  }
}

// MARK: - Localizable

extension Localized {
  enum Extension {
    static let confirmTitleFormat = String(localized: "Install “%@”?", comment: "Title (format) for the extension install confirmation")
    static let installButton = String(localized: "Install", comment: "Button title to confirm installing an extension")
    static let relaunchButton = String(localized: "Relaunch", comment: "Button title to relaunch the app after installing an extension")
    static let laterButton = String(localized: "Later", comment: "Button title to postpone relaunching after installing an extension")
    static let authorFormat = String(localized: "**Author:** %@", comment: "Extension author line (format) in the install confirmation")
    static let urlFormat = String(localized: "**URL:** %@", comment: "Extension URL line (format) in the install confirmation")
    static let fullAccessWarning = String(localized: "This extension runs with full editor access.", comment: "Disclosure shown before installing an extension")
    static let unreviewedWarning = String(localized: "This source is not reviewed by MarkEdit. Only continue if you trust it.", comment: "Caution shown before installing an extension from a raw URL")
    static let installedTitle = String(localized: "Extension Installed", comment: "Title for the extension installed confirmation")
    static let installedMessageFormat = String(localized: "Relaunch MarkEdit to start using “%@”.", comment: "Message (format) shown after an extension is installed")
    static let notFoundFormat = String(localized: "Couldn’t find the extension “%@” in the registry.", comment: "Error when a deep-link id does not resolve in the registry")
    static let failedTitle = String(localized: "Failed to install the extension.", comment: "Title for a failed extension installation")
    static let failedMessage = String(localized: "The extension couldn’t be downloaded or verified.", comment: "Message for a failed extension installation")
    static let incompatibleFormat = String(localized: "This extension requires MarkEdit %@ or later.", comment: "Error (format) when an extension needs a newer app version")
    static let updatesAvailableTitle = String(localized: "Extension Updates Available", comment: "Title for the extension updates prompt")
    static let updateButton = String(localized: "Update", comment: "Button title to install extension updates")
    static let updatedTitle = String(localized: "Extensions Updated", comment: "Title shown after extensions are updated")
    static let updatedMessage = String(localized: "Relaunch MarkEdit to use the updated extensions.", comment: "Message shown after extensions are updated")

    // MARK: - Manager UI

    static let managerTitle = String(localized: "MarkEdit Extensions", comment: "Title of the extension manager window")
    static let installed = String(localized: "Installed", comment: "Extension manager mode: installed extensions")
    static let discover = String(localized: "Discover", comment: "Extension manager mode: browse the registry")
    static let enabled = String(localized: "Enabled", comment: "Toggle title for enabling an installed extension")
    static let enabledTooltip = String(localized: "Turn off to keep the extension installed but inactive", comment: "Tooltip explaining the enable switch")
    static let uninstall = String(localized: "Uninstall", comment: "Button title to uninstall an extension")
    static let reveal = String(localized: "Reveal", comment: "Button title to reveal an extension's script file in Finder")
    static let uninstallConfirmFormat = String(localized: "Uninstall “%@”?", comment: "Title (format) to confirm uninstalling an extension")
    static let uninstallConfirmMessage = String(localized: "This removes its script from the scripts folder.", comment: "Message shown when confirming an extension uninstall")
    static let updateToFormat = String(localized: "Update to %@", comment: "Button title (format) to update an extension to a version")
    static let homepage = String(localized: "Homepage", comment: "Link to an extension's homepage")
    static let actions = String(localized: "Actions", comment: "Toolbar menu of extension manager actions")
    static let installFromURL = String(localized: "Install from URL…", comment: "Menu item to install an extension from a URL")
    static let installFromURLTitle = String(localized: "Install Extension from URL", comment: "Title for the install-from-URL prompt")
    static let openScriptsFolder = String(localized: "Open Scripts Folder", comment: "Menu item to reveal the extensions scripts folder")
    static let refresh = String(localized: "Refresh", comment: "Menu item to refetch the extension registry")
    static let refreshing = String(localized: "Refreshing…", comment: "State shown while the extension list is being refreshed")
    static let updateAll = String(localized: "Update All", comment: "Menu item to update all extensions with available updates")
    static let submitExtension = String(localized: "Submit an Extension…", comment: "Menu item to open the extension contributing guide")
    static let relaunchNotice = String(localized: "Relaunch to apply your changes.", comment: "Notice shown when extension changes need a relaunch")
    static let retry = String(localized: "Retry", comment: "Button to retry reaching the extension registry")
    static let registryUnreachable = String(localized: "Couldn’t reach the extension registry.", comment: "Error shown when the registry can't be loaded")
    static let emptyInstalled = String(localized: "No extensions installed.", comment: "Empty state for installed extensions")
    static let emptyDiscover = String(localized: "No extensions found.", comment: "Empty state for the Discover list")
  }
}
