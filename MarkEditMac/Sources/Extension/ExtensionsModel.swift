//
//  ExtensionsModel.swift
//  MarkEditMac
//
//  Created by cyan on 7/13/26.
//

import AppKit
import ExtensionCore
import MarkEditKit
import Observation

/// Presents the Extensions window's confirmation and failure alerts, owned by the view layer.
@MainActor
protocol ExtensionsPresenting: AnyObject {
  /// Confirms a destructive uninstall.
  func confirmUninstall(name: String) async -> Bool
  /// Reports an install/update failure.
  func reportFailure(_ error: Error) async
}

/// Backing state for the Extensions window.
///
/// The filesystem (via `ExtensionConfig`) and the registry (via `ExtensionRegistry`) are the
/// source of truth; this model flattens both into view-ready `Item` values for its modes.
@MainActor
@Observable
final class ExtensionsModel {
  enum Mode: Int, CaseIterable {
    case discover = 0
    case installed = 1
    case updates = 2

    /// Both installed and updates are backed by the local extensions list, not the Discover registry.
    var isLocalList: Bool {
      self == .installed || self == .updates
    }

    var title: String {
      switch self {
      case .discover: return Localized.Extension.discover
      case .installed: return Localized.Extension.installed
      case .updates: return Localized.Extension.updates
      }
    }

    var icon: String {
      switch self {
      case .discover: return Icons.sparkles
      case .installed: return Icons.shippingbox
      case .updates: return Icons.arrowDownCircle
      }
    }

    var emptyMessage: String {
      switch self {
      case .discover: return Localized.Extension.emptyDiscover
      case .installed: return Localized.Extension.emptyInstalled
      case .updates: return Localized.Extension.emptyUpdates
      }
    }
  }

  enum Phase: Equatable {
    case loading
    case ready
    case failed
  }

  /// A flattened, view-ready extension for any mode.
  struct Item: Identifiable, Equatable {
    let id: String
    let name: String
    let author: String
    let details: String
    let homepage: URL?
    let version: String?
    let isEnabled: Bool
    let isInstalled: Bool
    let updateVersion: String?

    // Backing values used to perform actions
    let installed: ExtensionConfig.Installed?
    let entry: ExtensionEntry?

    /// The registry category (extension or theme), when known.
    var category: ExtensionEntry.Category? {
      entry?.category
    }

    /// Palette(s) driving the illustrated theme preview.
    var colorPatterns: [String]? {
      entry?.colorPatterns
    }

    /// Light/dark scheme for the theme preview.
    var colorScheme: ExtensionEntry.ColorScheme? {
      entry?.colorScheme
    }

    /// Whether the author is the MarkEdit-app organization, shown as an official badge.
    var isOfficial: Bool {
      author.caseInsensitiveCompare("MarkEdit-app") == .orderedSame
    }

    /// Whether the registry marks this as a featured (recommended) entry.
    var isFeatured: Bool {
      entry?.featured ?? false
    }

    /// An installed extension with no tracked version, a local script not from the registry.
    var isLocal: Bool {
      isInstalled && version == nil
    }

    /// A browsable page for the latest release (release or tag page), when known.
    var latestReleaseURL: URL? {
      entry?.latest.pageURL
    }

    /// Release notes for the latest release.
    var updateNotes: String? {
      entry?.latest.notes
    }

    /// Whether the item matches a search query, by name, author, id, or details.
    func matches(query: String) -> Bool {
      [name, author, id, details].contains { $0.localizedCaseInsensitiveContains(query) }
    }
  }

  var mode: Mode = .discover
  var phase: Phase = .loading
  var hasLoadedIndex = false
  var pendingRelaunch = false
  var isBusy = false

  /// The view layer that presents alerts and owns the sheet and window.
  @ObservationIgnored weak var presenter: ExtensionsPresenting?

  /// The current search query; empty shows everything.
  var searchQuery = ""

  /// A whole-page progress message shown over the (emptied) list during Refresh or Update All.
  var loadingMessage: String?

  /// Determinate progress (completed, total) for a multi-extension "Update All"; nil shows an indeterminate spinner.
  var updateProgress: (completed: Int, total: Int)?

  /// The item currently running an install/update, used to show a per-item spinner.
  var busyItemID: String?

  private var discoverItems: [Item] = []
  private var installedItems: [Item] = []

  /// Items for the current mode, filtered to updatable extensions in the Updates mode and by the search query.
  var items: [Item] {
    var base = mode.isLocalList ? installedItems : discoverItems
    if mode == .updates {
      base = base.filter { $0.updateVersion != nil }
    }

    let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !query.isEmpty else {
      return base
    }

    return base.filter { $0.matches(query: query) }
  }

  /// Reordering applies only to the full installed list (the injection order), not filtered
  /// subsets like Updates or search, where a drag would persist a partial order.
  var canReorderItems: Bool {
    mode == .installed && searchQuery.isEmpty
  }

  /// Number of installed extensions with a newer release available.
  var availableUpdateCount: Int {
    installedItems.count { $0.updateVersion != nil }
  }

  /// The latest item for `id`, so a cell can read live state instead of a stale snapshot.
  func liveItem(id: String) -> Item? {
    items.first { $0.id == id }
  }

  /// Item count for `mode`, surfaced as the segment tooltip.
  func count(for mode: Mode) -> Int {
    switch mode {
    case .discover: return discoverItems.count
    case .installed: return installedItems.count
    case .updates: return availableUpdateCount
    }
  }
}

// MARK: - Loading

extension ExtensionsModel {
  /// Builds both lists synchronously from the cache, so the first paint shows content.
  func primeFromCache() {
    rebuildItems(index: ExtensionRegistry.cachedIndex)
  }

  /// Reconciles installed extensions with disk, refreshes the registry index, and rebuilds both lists.
  func load(forceRefresh: Bool = false) async {
    phase = .loading
    ExtensionConfig.reconcileInstalled()

    let index = await ExtensionRegistry.refresh(force: forceRefresh)
    rebuildItems(index: index)
    phase = index == nil ? .failed : .ready

    // A fresh index may surface or clear updates, let the menu-bar hint refresh
    ExtensionUpdater.requestMenuUpdate()
  }
}

// MARK: - Actions

extension ExtensionsModel {
  func setEnabled(_ enabled: Bool, for item: Item) {
    ExtensionConfig.setEnabled(enabled, forID: item.id)
    markChanged()
  }

  /// Persists a new injection order for the installed extensions.
  func reorderInstalled(orderedIDs: [String]) {
    ExtensionConfig.reorder(orderedIDs: orderedIDs)
    markChanged()
  }

  func uninstallExtension(_ item: Item) async {
    guard let installed = item.installed else {
      return
    }

    guard await presenter?.confirmUninstall(name: item.name) == true else {
      return
    }

    ExtensionDownloader.uninstall(installed)
    markChanged()
  }

  func installExtension(_ item: Item) async {
    guard let entry = item.entry else {
      return
    }

    await runBusyAction(itemID: item.id) {
      let record = try await ExtensionDownloader.install(entry: entry)
      ExtensionConfig.upsertInstalled(record)
    }
  }

  func updateExtension(_ item: Item) async {
    guard let installed = item.installed, let entry = item.entry else {
      return
    }

    await runBusyAction(itemID: item.id) {
      let merged = try await ExtensionDownloader.downloadUpdate(for: installed, entry: entry)
      ExtensionConfig.upsertInstalled(merged)
    }
  }

  /// Updates every installed extension that has a newer release.
  func updateAllExtensions() async {
    let updatable = installedItems.compactMap { item -> (ExtensionConfig.Installed, ExtensionEntry)? in
      guard let installed = item.installed, let entry = item.entry, item.updateVersion != nil else {
        return nil
      }

      return (installed, entry)
    }

    guard !updatable.isEmpty else {
      return
    }

    // Show determinate progress when more than one extension is being updated
    let total = updatable.count
    let tracksProgress = total > 1

    // Continue past per-item failures so one bad extension doesn't abort the batch
    var failures: [Error] = []
    await runBusyAction {
      // Set here (not before), so a re-entrant call doesn't flash a stale 0/total
      if tracksProgress {
        updateProgress = (0, total)
      }

      for (index, (installed, entry)) in updatable.enumerated() {
        do {
          let merged = try await ExtensionDownloader.downloadUpdate(for: installed, entry: entry)
          ExtensionConfig.upsertInstalled(merged)
        } catch {
          Logger.log(.error, "Failed to update extension \(installed.id): \(error)")
          failures.append(error)
        }

        if tracksProgress {
          updateProgress = (index + 1, total)
          if total < 10 {
            try? await Task.sleep(for: Constants.progressStepDelay)
          }
        }
      }
    }

    if let failure = failures.first {
      await presenter?.reportFailure(failure)
    }
  }

  func installExtension(from url: URL) async {
    await runBusyAction {
      let record = try await ExtensionDownloader.install(url: url)
      ExtensionConfig.upsertInstalled(record)
    }
  }

  func openScriptsFolder() {
    NSWorkspace.shared.open(AppCustomization.scriptsDirectory.fileURL)
  }

  /// Reveals the extension's script file in Finder, falling back to the scripts folder.
  func revealScriptFile(_ item: Item) {
    guard let file = item.installed?.file, !file.isEmpty else {
      return openScriptsFolder()
    }

    let fileURL = AppCustomization.scriptsDirectory.fileURL.appending(path: file, directoryHint: .notDirectory)
    NSWorkspace.shared.activateFileViewerSelecting([fileURL])
  }

  func relaunch() {
    NSWorkspace.shared.relaunchApp()
  }
}

// MARK: - Private

private extension ExtensionsModel {
  enum Constants {
    /// Minimum time the busy spinner stays visible so a fast action doesn't flash.
    static let minimumBusyDuration: TimeInterval = 1.2
    /// Brief settle so the swapped-in control renders before the spinner clears.
    static let busyRenderDelay: Duration = .milliseconds(50)
    /// Extra dwell after each "Update All" step so the count ticks up at a readable pace.
    static let progressStepDelay: Duration = .milliseconds(400)
  }

  /// Rebuilds both lists; `installed` is injectable so the mapping can be tested in isolation.
  func rebuildItems(index: ExtensionIndex?, installed: [ExtensionConfig.Installed] = ExtensionConfig.installed) {
    if index != nil {
      hasLoadedIndex = true
    }

    let entries = index?.extensions ?? []
    let entryByID = Dictionary(entries.map { ($0.id, $0) }) { lhs, _ in lhs }

    let updates = index.map { ExtensionRegistry.availableUpdates(index: $0, installed: installed) } ?? []
    let updateByID = Dictionary(updates.map { ($0.installed.id, $0.entry.latest.version) }) { lhs, _ in lhs }

    installedItems = extensionsFirst(installed.map { installed in
      let entry = entryByID[installed.id]
      return Item(
        id: installed.id,
        name: entry?.name ?? installed.id,
        author: entry?.author ?? "",
        details: entry?.description ?? "",
        homepage: entry.flatMap { URL(string: $0.homepage) },
        version: installed.version,
        isEnabled: installed.enabled != false,
        isInstalled: true,
        updateVersion: updateByID[installed.id],
        installed: installed,
        entry: entry
      )
    })

    let installedByID = Dictionary(installed.map { ($0.id, $0) }) { lhs, _ in lhs }
    discoverItems = discoverOrder(entries.map { entry in
      let installed = installedByID[entry.id]
      return Item(
        id: entry.id,
        name: entry.name,
        author: entry.author,
        details: entry.description,
        homepage: URL(string: entry.homepage),
        version: entry.latest.version,
        isEnabled: installed?.enabled != false,
        isInstalled: installed != nil,
        updateVersion: updateByID[entry.id],
        installed: installed,
        entry: entry
      )
    })
  }

  /// Extensions first, then themes, preserving each group's original order.
  func extensionsFirst(_ items: [Item]) -> [Item] {
    items.filter { $0.category == .extension } + items.filter { $0.category != .extension }
  }

  /// Discover order: extensions before themes, featured floated to the top of each group.
  func discoverOrder(_ items: [Item]) -> [Item] {
    let featuredFirst: ([Item]) -> [Item] = { items in
      items.filter { $0.isFeatured } + items.filter { !$0.isFeatured }
    }

    return extensionsFirst(featuredFirst(items))
  }

  /// Runs a mutating action in the busy state (ignoring re-entrant calls), keeping the spinner briefly visible and reporting failures.
  func runBusyAction(itemID: String? = nil, _ action: () async throws -> Void) async {
    guard !isBusy else {
      return
    }

    isBusy = true
    busyItemID = itemID
    defer {
      isBusy = false
      busyItemID = nil
    }

    let started = Date()
    do {
      try await action()
      let remaining = Constants.minimumBusyDuration - Date().timeIntervalSince(started)
      if remaining > 0 {
        try? await Task.sleep(for: .seconds(remaining))
      }

      // Apply the change (e.g. Install -> Reveal) while the spinner still covers the button,
      // then let it render before clearing busy; doing both at once cancels the fade-in.
      markChanged()
      try? await Task.sleep(for: Constants.busyRenderDelay)
    } catch is CancellationError {
      // Cancelled (e.g. the window closed mid-action); not a user-facing failure
    } catch {
      Logger.log(.error, "Extension action failed: \(error)")
      await presenter?.reportFailure(error)
    }
  }

  /// Marks changes as staged (surfacing the relaunch bar) and rebuilds from the cached index.
  func markChanged() {
    pendingRelaunch = true
    rebuildItems(index: ExtensionRegistry.cachedIndex)
    ExtensionUpdater.requestMenuUpdate()
  }
}
