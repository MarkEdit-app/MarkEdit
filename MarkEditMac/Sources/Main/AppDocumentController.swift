//
//  AppDocumentController.swift
//  MarkEditMac
//
//  Created by cyan on 10/14/24.
//

import AppKit
import MarkEditKit

/**
 Subclass of `NSDocumentController` to allow customizations.

 NSDocumentController.shared will be an instance of `AppDocumentController` at runtime.
 */
final class AppDocumentController: NSDocumentController {
  static var suggestedTextEncoding: EditorTextEncoding?
  static var suggestedFilename: String?

  override var maximumRecentDocumentCount: Int {
    8
  }

  override func beginOpenPanel(_ openPanel: NSOpenPanel, forTypes inTypes: [String]?) async -> Int {
    if let defaultDirectory = AppRuntimeConfig.defaultOpenDirectory {
      setOpenPanelDirectory(defaultDirectory)
    }

    if AppRuntimeConfig.disableOpenPanelOptions {
      openPanel.accessoryView = nil
    } else {
      openPanel.accessoryView = EditorSaveOptionsView.wrapper(for: .openPanel) { [weak openPanel] result in
        switch result {
        case .textEncoding(let value):
          Self.suggestedTextEncoding = value
        case .showHiddenFiles(let value):
          openPanel?.showsHiddenFiles = value
        default:
          Logger.assertFail("Invalid change: \(result)")
        }
      }
    }

    Self.suggestedTextEncoding = nil
    openPanel.showsHiddenFiles = AppPreferences.General.showHiddenFiles
    openPanel.relayoutAccessoryView()

    return await super.beginOpenPanel(openPanel, forTypes: inTypes)
  }

  override func openDocument(
    withContentsOf url: URL,
    display displayDocument: Bool,
    completionHandler: @escaping (NSDocument?, Bool, (any Error)?) -> Void
  ) {
    if url.isBinaryFile {
      // Dead loop prevention
      if Bundle.main.isDefaultApp(toOpen: url) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
      } else {
        NSWorkspace.shared.open(url)
      }

      // Ignore the default opening logic
      return completionHandler(nil, false, nil)
    }

    Task { @MainActor in
      // Ensure the preloader has a fully loaded editor before opening the document
      await EditorPreloader.shared.prepareViewController()

      // Pick a target tab-group host: if a usable editor window is up front,
      // we want the newly opened document to join that window's tab group
      // instead of becoming a standalone window. nil means "open standalone".
      let targetWindow = Self.tabTargetWindow(for: url)

      guard let targetWindow else {
        super.openDocument(
          withContentsOf: url,
          display: displayDocument,
          completionHandler: completionHandler
        )
        return
      }

      // Same pattern as reopenClosedTab: temporarily disable auto-tabbing so
      // the new window opens standalone, then we manually attach it to the
      // target's tab group. EditorWindowController.showWindow snapshots this
      // value synchronously, so it must be set before super.openDocument.
      Self.suppressAutomaticTabbing()
      super.openDocument(
        withContentsOf: url,
        display: displayDocument
      ) { document, alreadyOpen, error in
        Self.restoreAutomaticTabbing()

        if !alreadyOpen, error == nil,
           let editorDocument = document as? EditorDocument {
          Task { @MainActor in
            guard let newWindow = editorDocument.windowControllers.first?.window,
                  newWindow !== targetWindow,
                  newWindow.tabGroup !== targetWindow.tabGroup else {
              return
            }

            targetWindow.addTabbedWindow(newWindow, ordered: .above)
          }
        }

        completionHandler(document, alreadyOpen, error)
      }
    }
  }

  override func saveAllDocuments(_ sender: Any?) {
    // The default implementation doesn't work
    documents.forEach { $0.save(sender) }
  }
}

// MARK: - Automatic tabbing suppression

extension AppDocumentController {
  private enum AutoTabbingStates {
    @MainActor static var inFlightCount = 0
    @MainActor static var savedValue: Bool?
  }

  /// Temporarily forces `NSWindow.allowsAutomaticWindowTabbing` to `false`.
  ///
  /// Reference-counted so overlapping callers (e.g. rapid Cmd+Shift+T, or a
  /// batch of files opened together) don't clobber each other's saved state.
  /// Pair every call with `restoreAutomaticTabbing()`.
  @MainActor
  static func suppressAutomaticTabbing() {
    if AutoTabbingStates.inFlightCount == 0 {
      AutoTabbingStates.savedValue = NSWindow.allowsAutomaticWindowTabbing
      NSWindow.allowsAutomaticWindowTabbing = false
    }

    AutoTabbingStates.inFlightCount += 1
  }

  @MainActor
  static func restoreAutomaticTabbing() {
    AutoTabbingStates.inFlightCount -= 1
    if AutoTabbingStates.inFlightCount == 0 {
      NSWindow.allowsAutomaticWindowTabbing = AutoTabbingStates.savedValue ?? true
      AutoTabbingStates.savedValue = nil
    }
  }
}

// MARK: - Private

private extension AppDocumentController {
  @MainActor
  static func tabTargetWindow(for url: URL) -> EditorWindow? {
    if AppPreferences.Window.tabbingMode == .disallowed {
      return nil
    }

    // If the document is already open, NSDocumentController will reuse it and
    // raise its existing window/tab — we must not inject a new tab attachment.
    let alreadyOpen = NSDocumentController.shared.documents.contains { document in
      guard let existing = document.fileURL else {
        return false
      }

      return existing == url || existing.resolvingSymlinksInPath() == url.resolvingSymlinksInPath()
    }

    if alreadyOpen {
      return nil
    }

    return (NSApp.keyWindow as? EditorWindow) ?? (NSApp.mainWindow as? EditorWindow)
  }
}

private extension NSOpenPanel {
  /// Re-layouts the accessory view to work around internal AppKit bugs.
  ///
  /// For example, the animation of opening documents will sometimes be skipped.
  func relayoutAccessoryView() {
    accessoryView?.needsLayout = true
  }
}
