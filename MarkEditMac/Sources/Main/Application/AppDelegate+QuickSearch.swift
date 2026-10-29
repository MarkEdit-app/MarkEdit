//
//  AppDelegate+QuickSearch.swift
//  MarkEditMac
//
//  Created by cyan on 10/11/26.
//

import AppKit
import AppKitExtensions
import MarkEditKit
import QuickSearchCore
import QuickSearchUI

extension AppDelegate {
  static func refocusSourceWindow(_ window: NSWindow) async throws {
    window.makeKeyAndOrderFront(nil)

    guard let editor = window.contentViewController as? EditorViewController else {
      return
    }

    guard window.firstResponder === editor.webView else {
      return
    }

    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
      editor.bridge.core.restoreFocus {
        continuation.resume(with: $0)
      }
    }
  }

  @IBAction func quickSearch(_ sender: Any?) {
    if let window = quickSearchController?.window, window.isVisible || window.isActivatingResult {
      if !window.isActivatingResult {
        window.makeKeyAndOrderFront(sender)
        window.focusInput()
      }

      return
    }

    let sourceWindow = NSApp.keyWindow
    guard let screen = sourceWindow?.screen ?? NSScreen.main else {
      Logger.log(.error, "No screen available for Quick Search")
      return
    }

    quickSearchSourceWindow = sourceWindow
    if quickSearchController == nil {
      quickSearchController = QuickSearchController(
        effectViewType: AppDesign.modernEffectView,
        placeholder: { filter in
          let target = switch filter {
          case .all: Localized.QuickSearch.allTarget
          case .headings: Localized.QuickSearch.headingsTarget
          case .contents: Localized.QuickSearch.contentsTarget
          case .recents: Localized.QuickSearch.recentsTarget
          case .bookmarks: Localized.QuickSearch.bookmarksTarget
          case .menuActions: Localized.QuickSearch.menuActionsTarget
          }

          return Localized.QuickSearch.placeholder(for: target)
        },
        accessibilityHelp: Localized.QuickSearch.help,
        filterLabels: QuickSearchFilterLabels(
          title: Localized.QuickSearch.filterResults,
          all: Localized.General.all,
          recents: Localized.QuickSearch.recents,
          bookmarks: Localized.QuickSearch.bookmarks,
          headings: Localized.QuickSearch.headings,
          contents: Localized.QuickSearch.contents,
          menuActions: Localized.QuickSearch.menuActions,
          currentDocument: Localized.QuickSearch.currentDocument
        ),
        filterMenuHelp: (Localized.QuickSearch.helpTitle, {
          NSWorkspace.shared.safelyOpenURL(string: "https://github.com/MarkEdit-app/MarkEdit/wiki/Manual#quick-search")
        }),
        reportError: { Logger.log(.error, "Quick Search: \($0)") },
        onResultActivated: { AppPreferences.General.hasUsedQuickSearch = true },
        openDocument: { [weak self] url in
          guard let self else {
            throw CancellationError()
          }

          guard let controller = NSDocumentController.shared as? AppDocumentController else {
            Logger.assertFail("Missing AppDocumentController")
            throw CocoaError(.fileReadUnknown)
          }

          try await controller.openDocument(at: url, target: .automatic, relativeTo: self.quickSearchSourceWindow)
        }
      )
    }

    NSApp.closeOpenPanels()
    quickSearchController?.present(
      recentURLs: NSDocumentController.shared.recentDocumentURLs,
      locations: { [bookmarkStore] in
        let bookmarks = bookmarkStore.load()
        return QuickSearchLocations(
          urls: bookmarks.compactMap(\.url),
          showsHiddenFiles: AppPreferences.General.showHiddenFiles,
          isFileEligible: { !$0.isBinaryFile },
          errors: bookmarks.compactMap { $0.error?.localizedDescription }
        )
      },
      document: quickSearchDocument(in: sourceWindow),
      menu: NSApp.mainMenu,
      openRecentMenu: openRecentMenu,
      refocusSourceWindow: { [weak sourceWindow] in
        guard let sourceWindow else {
          throw CancellationError()
        }

        try await Self.refocusSourceWindow(sourceWindow)
      },
      screen: screen,
      appearance: AppTheme.current.resolvedAppearance,
      tintColor: quickSearchTintColor
    )
  }

  func updateQuickSearchAppearance() {
    guard let window = quickSearchController?.window else {
      return
    }

    window.appearance = AppTheme.current.resolvedAppearance
    window.tintColor = quickSearchTintColor
  }
}

extension Localized {
  enum QuickSearch {
    static let helpTitle = String(localized: "Help…", comment: "Quick Search filter menu item opening its documentation")
    static let openPanelHint = String(localized: "Find files faster with Quick Search (⇧⌘O).", comment: "Open panel hint, hidden after the first successful Quick Search action")
    static let title = String(localized: "Quick Search", comment: "Quick Search option in new window settings")
    static let filterResults = String(localized: "Filter Results", comment: "Quick Search filter menu accessibility label")
    static let recents = String(localized: "Recents", comment: "Quick Search filter for recent documents")
    static let bookmarks = String(localized: "Bookmarks", comment: "Quick Search filter for granted files and folders")
    static let headings = String(localized: "Headings", comment: "Quick Search filter for active-document headings")
    static let contents = String(localized: "Contents", comment: "Quick Search filter for active-document text")
    static let menuActions = String(localized: "Menu Actions", comment: "Quick Search filter for menu actions")
    static let currentDocument = String(localized: "Current Document", comment: "Quick Search filter section for the active document")
    static let help = String(localized: "Search files, the current document, and menu actions", comment: "Accessibility help for Quick Search")
    static let allTarget = String(localized: "files, text, and commands", comment: "Search target in the Quick Search placeholder")
    static let headingsTarget = String(localized: "headings", comment: "Search target in the Quick Search placeholder")
    static let contentsTarget = String(localized: "text", comment: "Search target in the Quick Search placeholder")
    static let recentsTarget = String(localized: "recent files", comment: "Search target in the Quick Search placeholder")
    static let bookmarksTarget = String(localized: "bookmarked files", comment: "Search target in the Quick Search placeholder")
    static let menuActionsTarget = String(localized: "commands", comment: "Search target in the Quick Search placeholder")

    static func placeholder(for target: String) -> String {
      String(format: String(localized: "Quick Search for %@", comment: "Quick Search placeholder, with a localized search target"), target)
    }
  }
}

// MARK: - Private

private extension AppDelegate {
  func quickSearchDocument(in window: NSWindow?) -> QuickSearchDocument? {
    guard let editor = window?.contentViewController as? EditorViewController, let document = editor.document else {
      return nil
    }

    typealias Source = (editor: EditorViewController, document: EditorDocument, window: NSWindow)
    let resolveSource: () throws -> Source = { [weak editor, weak document] in
      guard let editor, let document, editor.document === document,
            let window = editor.viewIfLoaded?.window,
            NSDocumentController.shared.documents.contains(where: { $0 === document }) else {
        throw QuickSearchDocumentError.unavailable
      }

      return (editor, document, window)
    }

    var cachedSnapshot: (text: String, revision: String)?
    return QuickSearchDocument(
      id: document.sessionID,
      title: document.displayName ?? document.defaultDraftName(),
      url: document.fileURL,
      readSnapshot: {
        let source = try resolveSource()
        let cached = cachedSnapshot
        let outline = try await source.editor.bridge.toc.getDocumentOutline(knownRevision: cached?.revision)
        _ = try resolveSource()

        let text: String
        if let updatedText = outline.text {
          text = updatedText
        } else if let cached, cached.revision == outline.revision {
          text = cached.text
        } else {
          Logger.assertFail("Missing text for an uncached editor revision")
          throw CocoaError(.fileReadCorruptFile)
        }

        cachedSnapshot = (text: text, revision: outline.revision)
        return QuickSearchDocumentSnapshot(
          text: text,
          headings: outline.headings.map {
            QuickSearchHeading(title: $0.title, level: $0.level, lineNumber: $0.lineNumber)
          }
        )
      },
      gotoLine: { lineNumber in
        let source = try resolveSource()
        source.window.makeKeyAndOrderFront(nil)
        source.editor.startTextEditing()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
          source.editor.bridge.selection.gotoLine(lineNumber: lineNumber) {
            continuation.resume(with: $0)
          }
        }
      }
    )
  }

  var quickSearchTintColor: NSColor? {
    let theme = AppTheme.current

    if let editor = quickSearchSourceWindow?.contentViewController as? EditorViewController {
      return editor.transientTintColor(for: theme)
    }

    return theme.prefersTintedColors ? theme.windowBackground.withAlphaComponent(0.5).resolvedColor() : nil
  }
}
