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
        placeholder: Localized.QuickSearch.placeholder,
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
        reportError: { Logger.log(.error, "Quick Search: \($0)") },
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

    let bookmarks = bookmarkStore.load()
    let types = Bundle.main.infoDictionary?["CFBundleDocumentTypes"] as? [[String: Any]] ?? []
    let extensions = types.flatMap { $0["CFBundleTypeExtensions"] as? [String] ?? [] }

    quickSearchController?.present(
      recentURLs: NSDocumentController.shared.recentDocumentURLs,
      locations: QuickSearchLocations(
        urls: bookmarks.compactMap(\.url),
        filenameExtensions: Set(extensions.map { $0.lowercased() }),
        showsHiddenFiles: AppPreferences.General.showHiddenFiles,
        errors: bookmarks.compactMap { $0.error?.localizedDescription }
      ),
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
