//
//  QuickSearchController.swift
//
//  Created by cyan on 10/11/26.
//

import AppKit
import AppKitExtensions
import QuickSearchCore

@MainActor
public final class QuickSearchController: NSObject {
  public private(set) var window: QuickSearchWindow?

  private let effectViewType: NSView.Type
  private let placeholder: (QuickSearchFilter) -> String
  private let accessibilityHelp: String
  private let filterLabels: QuickSearchFilterLabels
  private let filterMenuHelp: (title: String, action: () -> Void)?
  private let reportError: (String) -> Void
  private let onResultActivated: () -> Void
  private let openDocument: (URL) async throws -> Void
  private let breadcrumbSeparator = " \u{203A} "
  private var recentURLs: [URL] = []
  private var discoveredURLs: [URL] = []
  private var locations: (() -> QuickSearchLocations)?
  private var discoveryNeedsRefresh = false
  private var lastDiscoveryRefresh = ContinuousClock.now
  private var document: QuickSearchDocument?
  private var menuActions: QuickSearchMenuActions?
  private var documentSnapshot: QuickSearchDocumentSnapshot?
  private var displayedDocumentSnapshot: QuickSearchDocumentSnapshot?
  private var results: [QuickSearchResult] = []
  private var cachedResults: CachedResults?
  private var isPreparingResults = false
  private var isReadingDocument = false
  private var isDiscovering = false
  private var query = ""
  private var resultsQuery = ""
  private var lastQuery = ""
  private var filter: QuickSearchFilter = .all
  private var resultsFilter: QuickSearchFilter = .all
  private var filterMenu: NSMenu?
  private var invocation = 0
  private var queryRevision = 0
  private var activationTask: Task<Void, Never>?
  private var discoveryTask: Task<Void, Never>?
  private var documentTask: Task<Void, Never>?
  private var searchTask: Task<Void, Never>?

  public init(
    effectViewType: NSView.Type,
    placeholder: @escaping (QuickSearchFilter) -> String,
    accessibilityHelp: String,
    filterLabels: QuickSearchFilterLabels,
    filterMenuHelp: (title: String, action: () -> Void)? = nil,
    reportError: @escaping (String) -> Void,
    onResultActivated: @escaping () -> Void = {},
    openDocument: @escaping (URL) async throws -> Void
  ) {
    self.effectViewType = effectViewType
    self.placeholder = placeholder
    self.accessibilityHelp = accessibilityHelp
    self.filterLabels = filterLabels
    self.filterMenuHelp = filterMenuHelp
    self.reportError = reportError
    self.onResultActivated = onResultActivated
    self.openDocument = openDocument
    super.init()
  }

  public func present(
    recentURLs: [URL],
    locations: (() -> QuickSearchLocations)? = nil,
    document: QuickSearchDocument? = nil,
    menu: NSMenu? = nil,
    openRecentMenu: NSMenu? = nil,
    suggestedActions: [Selector] = [],
    refocusSourceWindow: (@MainActor () async throws -> Void)? = nil,
    screen: NSScreen,
    appearance: NSAppearance? = nil,
    tintColor: NSColor? = nil
  ) {
    if let window, window.isVisible || window.isActivatingResult {
      if !window.isActivatingResult {
        window.makeKeyAndOrderFront(nil)
        window.focusInput()
      }

      return
    }

    cancel()
    self.recentURLs = recentURLs
    self.locations = locations
    self.document = document

    menuActions = menu.map {
      QuickSearchMenuActions(
        menu: $0,
        sourceWindow: NSApp.keyWindow,
        openRecentMenu: openRecentMenu,
        suggestedActions: suggestedActions,
        refocusSourceWindow: refocusSourceWindow
      )
    }

    discoveredURLs = []
    documentSnapshot = nil
    displayedDocumentSnapshot = nil

    query = lastQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    isPreparingResults = true
    isReadingDocument = document != nil

    let invocation = invocation
    let window = QuickSearchWindow(
      effectViewType: effectViewType,
      tintColor: tintColor,
      relativeTo: screen.visibleFrame,
      visibleFrame: screen.visibleFrame,
      placeholder: placeholder(filter),
      accessibilityHelp: accessibilityHelp,
      iconName: "magnifyingglass",
      defaultText: lastQuery,
      results: QuickSearchResultsConfiguration(
        filterMenu: makeFilterMenu(),
        onQueryChange: { [weak self] query in
          guard let self, self.invocation == invocation else {
            return
          }

          self.lastQuery = query
          self.isPreparingResults = false
          self.search(query)
        },
        onActivate: { [weak self] id in
          guard let self, self.invocation == invocation else {
            return
          }

          self.activate(id)
        },
        onDismiss: { [weak self] in
          guard let self, self.invocation == invocation else {
            return
          }

          self.cancel()
        }
      )
    )

    self.window = window
    window.appearance = appearance
    window.setFilterActive(filter != .all)

    if let cachedResults, cachedResults.documentID == document?.id,
       cachedResults.query == query, cachedResults.filter == filter {
      results = cachedResults.results
      resultsQuery = cachedResults.query
      resultsFilter = cachedResults.filter
      displayedDocumentSnapshot = cachedResults.documentSnapshot
      window.updateResults(cachedResults.items, preserveSelection: false)
    }

    search(lastQuery)
    window.makeKeyAndOrderFront(nil)
    window.focusInput()

    refreshDocument()
  }

  public static func interceptOpenPanelShortcut(
    in panel: NSOpenPanel,
    registerShortcut: @escaping (@escaping @MainActor @Sendable () -> Void) -> (@MainActor @Sendable () -> Void)?,
    present: () async -> Int
  ) async -> (response: Int, quickSearchRequested: Bool) {
    let shortcut = OpenPanelShortcut(panel: panel, register: registerShortcut)
    defer { shortcut.stop() }

    let response = await present()
    return (response, shortcut.quickSearchRequested)
  }

  public func refreshDocument() {
    guard let document, window?.isVisible == true else {
      return
    }

    documentTask?.cancel()
    isReadingDocument = true

    let invocation = invocation
    documentTask = Task { [weak self] in
      defer {
        if let self, self.invocation == invocation, !Task.isCancelled, self.isReadingDocument {
          self.documentTask = nil
          self.isReadingDocument = false
          self.search(self.query, preserveSelection: true)
        }
      }

      do {
        let snapshot = try await document.readSnapshot()

        guard let self, self.invocation == invocation, !Task.isCancelled else {
          return
        }

        self.documentSnapshot = snapshot
      } catch is CancellationError {
        return
      } catch QuickSearchDocumentError.unavailable {
        guard let self, self.invocation == invocation, !Task.isCancelled else {
          return
        }

        self.documentTask = nil
        self.removeDocument()
      } catch {
        guard let self, self.invocation == invocation, !Task.isCancelled else {
          return
        }

        self.reportError(error.localizedDescription)
      }
    }
  }
}

// MARK: - Private

private extension QuickSearchController {
  func makeFilterMenu() -> NSMenu {
    let menu = NSMenu(title: filterLabels.title)
    menu.autoenablesItems = false

    for (index, option) in filterLabels.options.enumerated() {
      if option.filter == .headings {
        menu.addItem(.sectionHeader(title: filterLabels.currentDocument))
      }

      let item = NSMenuItem(
        title: option.title,
        action: #selector(selectFilter(_:)),
        keyEquivalent: String(index)
      )

      item.keyEquivalentModifierMask = .command
      item.target = self
      item.tag = option.filter.rawValue
      item.state = option.filter == filter ? .on : .off
      menu.addItem(item)

      if option.filter == .all || option.filter == .contents {
        menu.addItem(.separator())
      }
    }

    if let filterMenuHelp {
      menu.addItem(.separator())
      menu.addItem(withTitle: filterMenuHelp.title, action: filterMenuHelp.action)
    }

    filterMenu = menu
    return menu
  }

  @objc func selectFilter(_ sender: NSMenuItem) {
    guard sender.menu === filterMenu, window?.isVisible == true, window?.isActivatingResult == false else {
      return
    }

    guard let filter = QuickSearchFilter(rawValue: sender.tag) else {
      assertionFailure("Unknown Quick Search filter")
      return
    }
    guard filter != self.filter else {
      return
    }

    self.filter = filter
    isPreparingResults = false

    sender.menu?.items.forEach {
      $0.state = $0 === sender ? .on : .off
    }

    window?.setFilterActive(filter != .all)
    window?.setPlaceholder(placeholder(filter))
    search(query)
    window?.focusInput()
  }

  func search(_ query: String, preserveSelection: Bool = false) {
    discoveryNeedsRefresh = false
    lastDiscoveryRefresh = .now
    searchTask?.cancel()
    queryRevision += 1
    self.query = query.trimmingCharacters(in: .whitespacesAndNewlines)

    let needsBookmarks = filter == .bookmarks || filter == .all && !self.query.isEmpty
    if needsBookmarks, let locations {
      self.locations = nil
      isDiscovering = true

      let locations = locations()
      locations.errors.forEach(reportError)
      discover(locations)
    }

    if isPreparingResults {
      let needsDocument = filter == .all || filter == .headings || filter == .contents
      guard !(needsDocument && isReadingDocument), !(needsBookmarks && isDiscovering) else {
        return
      }

      isPreparingResults = false
    }

    let filter = filter
    let recentURLs = recentURLs
    let bookmarkedURLs = discoveredURLs
    let snapshot = documentSnapshot
    let actions = menuActions?.actions ?? []

    if self.query.isEmpty && filter != .bookmarks {
      do {
        results = try QuickSearchResult.search(
          self.query,
          filter: filter,
          recentURLs: recentURLs,
          bookmarkedURLs: bookmarkedURLs,
          snapshot: snapshot,
          menuActions: actions
        )
        displayedDocumentSnapshot = snapshot
      } catch is CancellationError {
        return
      } catch {
        reportError(error.localizedDescription)
        return
      }

      resultsQuery = self.query
      resultsFilter = filter
      render(preserveSelection: preserveSelection)
      return
    }

    let query = self.query
    let invocation = invocation
    let revision = queryRevision
    searchTask = Task.detached(priority: .userInitiated) { [weak self] in
      do {
        let results = try QuickSearchResult.search(
          query,
          filter: filter,
          recentURLs: recentURLs,
          bookmarkedURLs: bookmarkedURLs,
          snapshot: snapshot,
          menuActions: actions
        )

        await self?.apply(
          results,
          snapshot: snapshot,
          invocation: invocation,
          revision: revision
        )
      } catch is CancellationError {
        return
      } catch {
        await self?.searchFailed(error.localizedDescription, invocation: invocation, revision: revision)
      }
    }
  }

  func apply(
    _ results: [QuickSearchResult],
    snapshot: QuickSearchDocumentSnapshot?,
    invocation: Int,
    revision: Int
  ) {
    guard self.invocation == invocation, queryRevision == revision else {
      return
    }

    let preserveSelection = resultsQuery == query && resultsFilter == filter
    resultsQuery = query
    resultsFilter = filter
    self.results = results
    displayedDocumentSnapshot = snapshot
    render(preserveSelection: preserveSelection)
  }

  func searchFailed(_ message: String, invocation: Int, revision: Int) {
    guard self.invocation == invocation, queryRevision == revision else {
      return
    }

    reportError(message)
  }

  func render(preserveSelection: Bool = true) {
    let recentFiles = resultsFilter == .bookmarks ? Set<URL>() : Set(recentURLs.map(\.standardizedFileURL))
    let items = results.map { result in
      switch result {
      case .file(let file):
        var subtitleRanges: [NSRange] = []
        var subtitleFocusRange: NSRange?

        if let index = file.matchedFolderIndex {
          let components = file.url.pathComponents.filter { $0 != "/" }
          let offset = components.prefix(index).reduce(0) { $0 + $1.utf16.count + breadcrumbSeparator.utf16.count }
          subtitleFocusRange = NSRange(location: offset, length: components[index].utf16.count)
          subtitleRanges = file.match.ranges.map {
            NSRange(location: offset + $0.location, length: $0.length)
          }
        }

        return QuickSearchItem(
          id: result.id,
          title: file.url.lastPathComponent,
          subtitle: breadcrumb(file.url),
          iconName: recentFiles.contains(file.url) ? "clock" : "bookmark",
          highlightedRanges: file.matchedFolderIndex == nil ? file.match.ranges : [],
          subtitleHighlightedRanges: subtitleRanges,
          subtitleFocusRange: subtitleFocusRange
        )
      case .content(let content):
        return QuickSearchItem(
          id: result.id,
          title: content.snippet,
          subtitle: "\(document?.url.map(breadcrumb) ?? document?.title ?? ""):\(content.lineNumber)",
          iconName: "text.alignleft",
          iconColor: .systemMint,
          highlightedRanges: [content.highlightedRange]
        )
      case .heading(let match):
        return QuickSearchItem(
          id: result.id,
          title: match.heading.title,
          subtitle: "\(document?.url.map(breadcrumb) ?? document?.title ?? ""):\(match.heading.lineNumber)",
          iconName: "\(match.heading.level).square",
          iconColor: .systemOrange,
          highlightedRanges: match.match.ranges
        )
      case .menuAction(let match):
        return QuickSearchItem(
          id: result.id,
          title: match.action.title,
          subtitle: match.action.subtitle,
          iconName: "command",
          iconColor: .systemIndigo,
          highlightedRanges: match.highlightedRanges,
          shortcutHint: match.action.shortcutHint
        )
      }
    }

    window?.updateResults(items, preserveSelection: preserveSelection)
    cachedResults = CachedResults(
      documentID: document?.id,
      query: resultsQuery,
      filter: resultsFilter,
      results: results,
      items: items,
      documentSnapshot: displayedDocumentSnapshot
    )
  }

  func breadcrumb(_ url: URL) -> String {
    url.pathComponents.filter { $0 != "/" }.joined(separator: breadcrumbSeparator)
  }

  func discover(_ locations: QuickSearchLocations) {
    let invocation = invocation
    discoveryTask = Task.detached(priority: .utility) { [weak self] in
      do {
        try await FileDiscovery.scan(locations) { [weak self] batch in
          await self?.receive(batch, invocation: invocation)
        }
      } catch is CancellationError {
        return
      } catch {
        await self?.receive(.init(errors: [error.localizedDescription]), invocation: invocation)
      }

      guard !Task.isCancelled else {
        return
      }

      await self?.receive(.init(), invocation: invocation, isFinal: true)
    }
  }

  func receive(_ batch: FileDiscovery.Batch, invocation: Int, isFinal: Bool = false) {
    guard self.invocation == invocation else {
      return
    }

    discoveredURLs.append(contentsOf: batch.urls)
    batch.errors.forEach(reportError)
    discoveryNeedsRefresh = discoveryNeedsRefresh || !batch.urls.isEmpty
    if isFinal {
      isDiscovering = false
    }

    if isPreparingResults {
      search(query, preserveSelection: true)
      return
    }

    guard discoveryNeedsRefresh, filter == .bookmarks || filter == .all && !query.isEmpty else {
      return
    }

    // Coalesce discovery refreshes without delaying typing or the final batch
    guard isFinal || lastDiscoveryRefresh.duration(to: .now) >= .milliseconds(100) else {
      return
    }

    search(query, preserveSelection: true)
  }

  func removeDocument() {
    documentTask?.cancel()
    isReadingDocument = false
    document = nil
    documentSnapshot = nil
    displayedDocumentSnapshot = nil

    results.removeAll {
      switch $0 {
      case .heading, .content: true
      case .file, .menuAction: false
      }
    }

    render()
    search(query, preserveSelection: true)
  }

  func activateLine(_ lineNumber: Int, snapshot: QuickSearchDocumentSnapshot?) async throws -> Bool {
    guard let document else {
      return false
    }

    do {
      let latest = try await document.readSnapshot()
      try Task.checkCancellation()

      guard latest == snapshot else {
        documentSnapshot = latest
        search(query, preserveSelection: true)
        return false
      }

      try await document.gotoLine(lineNumber)
      return true
    } catch QuickSearchDocumentError.unavailable {
      try Task.checkCancellation()
      removeDocument()
      return false
    }
  }

  func activate(_ id: String) {
    guard let window, !window.isActivatingResult else {
      return
    }

    guard resultsQuery == query, resultsFilter == filter else {
      NSSound.beep()
      return
    }

    guard let result = results.first(where: { $0.id == id }) else {
      assertionFailure("Cannot activate a result outside the current query")
      return
    }

    let invocation = invocation
    let snapshot = displayedDocumentSnapshot
    window.isActivatingResult = true
    activationTask = Task { [weak self, weak window] in
      guard let self, let window else {
        return
      }

      defer {
        if self.invocation == invocation {
          self.activationTask = nil
        }
      }

      do {
        try Task.checkCancellation()
        let didActivate: Bool

        switch result {
        case .file(let file):
          try await self.openDocument(file.url)
          didActivate = true
        case .content(let content):
          didActivate = try await self.activateLine(content.lineNumber, snapshot: snapshot)
        case .heading(let result):
          didActivate = try await self.activateLine(result.heading.lineNumber, snapshot: snapshot)
        case .menuAction(let match):
          window.orderOut(nil)
          let item = try await self.menuActions?.resolve(match.action)

          guard self.invocation == invocation, !Task.isCancelled else {
            return
          }

          window.isActivatingResult = false
          self.cancel()

          guard item?.performAction() == true else {
            self.reportError("Menu action is no longer available: \(match.action.subtitle)")
            NSSound.beep()
            return
          }

          self.onResultActivated()
          return
        }

        guard self.invocation == invocation, !Task.isCancelled else {
          return
        }

        window.isActivatingResult = false
        if didActivate {
          // Focus transfer may have already hidden the palette without notifying dismissal
          self.cancel()
          self.onResultActivated()
          window.orderOut(nil)
        } else {
          window.focusInput()
        }
      } catch is CancellationError {
        guard self.invocation == invocation else {
          return
        }

        window.isActivatingResult = false
        window.orderOut(nil)
      } catch {
        guard self.invocation == invocation, !Task.isCancelled else {
          return
        }

        window.isActivatingResult = false
        self.reportError(error.localizedDescription)
        self.search(self.query, preserveSelection: true)

        if NSApp.isActive {
          window.makeKeyAndOrderFront(nil)
          window.focusInput()
        } else {
          window.orderOut(nil)
        }
      }
    }
  }

  func cancel() {
    invocation += 1
    activationTask?.cancel()
    activationTask = nil

    discoveryTask?.cancel()
    discoveryTask = nil

    documentTask?.cancel()
    documentTask = nil

    searchTask?.cancel()
    searchTask = nil

    document = nil
    menuActions = nil
    locations = nil
    documentSnapshot = nil
    displayedDocumentSnapshot = nil
    discoveredURLs = []
    discoveryNeedsRefresh = false
    results = []
    resultsQuery = ""
    filterMenu = nil
    isPreparingResults = false
    isReadingDocument = false
    isDiscovering = false
  }
}

private struct CachedResults {
  let documentID: UUID?
  let query: String
  let filter: QuickSearchFilter
  let results: [QuickSearchResult]
  let items: [QuickSearchItem]
  let documentSnapshot: QuickSearchDocumentSnapshot?
}
