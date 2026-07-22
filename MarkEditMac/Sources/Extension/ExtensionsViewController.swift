//
//  ExtensionsViewController.swift
//  MarkEditMac
//
//  Created by cyan on 7/14/26.
//

import AppKit
import AppKitExtensions
import ExtensionCore
import SharedUI
import SwiftUI
import Observation

/// Hosts the extension list in an AppKit `NSTableView` (SwiftUI cells) for native
/// titlebar separators, drag-to-reorder, and row animations.
@MainActor
final class ExtensionsViewController: NSViewController {
  static let defaultContentRect = CGRect(x: 0, y: 0, width: 780, height: 580)

  private let model: ExtensionsModel
  private let scrollView = NSScrollView()
  private let tableView = NSTableView()

  private var displayedItems: [ExtensionsModel.Item] = []
  private var displayedMode: ExtensionsModel.Mode

  /// While true, a whole-page overlay task (Refresh or Update All) drives the table and the observation-driven diff steps aside.
  private var isRunningProgressOverlay = false

  /// Mirrors `model.pendingRelaunch` for layout; toggled with a slide-up animation on show.
  private var displayedRelaunch = false
  private var isAnimatingRelaunch = false
  private var pendingScrollCategory: ExtensionEntry.Category?

  private lazy var stateController = NSHostingController(
    rootView: ExtensionsStateView(model: model)
  )

  private lazy var relaunchController = NSHostingController(
    rootView: ExtensionsInfoBar(model: model)
  )

  init(model: ExtensionsModel) {
    self.model = model
    self.displayedMode = model.mode
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    view = NSView(frame: Self.defaultContentRect)
    configureTableView()
    configureAccessoryViews()
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    model.presenter = self

    displayedItems = model.items
    displayedRelaunch = model.pendingRelaunch
    tableView.reloadData()

    updateStateController()
    observeModelChanges()
  }

  override func viewDidLayout() {
    super.viewDidLayout()
    guard !isAnimatingRelaunch else {
      return
    }

    layoutContents()
  }
}

// MARK: - NSTableViewDataSource

extension ExtensionsViewController: NSTableViewDataSource {
  func numberOfRows(in tableView: NSTableView) -> Int {
    displayedItems.count
  }

  func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
    guard model.canReorderItems, row < displayedItems.count else {
      return nil
    }

    let item = NSPasteboardItem()
    item.setString(displayedItems[row].id, forType: .string)
    return item
  }

  func tableView(
    _ tableView: NSTableView,
    validateDrop info: any NSDraggingInfo,
    proposedRow row: Int,
    proposedDropOperation dropOperation: NSTableView.DropOperation
  ) -> NSDragOperation {
    guard model.canReorderItems,
          dropOperation == .above,
          info.draggingSource as? NSTableView === tableView else {
      return []
    }

    return .move
  }

  func tableView(
    _ tableView: NSTableView,
    acceptDrop info: any NSDraggingInfo,
    row: Int,
    dropOperation: NSTableView.DropOperation
  ) -> Bool {
    guard model.canReorderItems,
          let identifier = info.draggingPasteboard.string(forType: .string),
          let source = (displayedItems.firstIndex { $0.id == identifier })
    else {
      return false
    }

    let destination = source < row ? row - 1 : row
    guard destination != source else {
      return false
    }

    let moved = displayedItems.remove(at: source)
    displayedItems.insert(moved, at: destination)

    tableView.performBatchUpdates {
      tableView.moveRow(at: source, to: destination)
    }

    model.reorderInstalled(orderedIDs: displayedItems.map(\.id))
    return true
  }
}

// MARK: - NSTableViewDelegate

extension ExtensionsViewController: NSTableViewDelegate {
  func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
    false
  }

  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let cell = tableView.makeView(withIdentifier: Constants.cellIdentifier, owner: self) as? TableCellWrapper ?? {
      let view = TableCellWrapper()
      view.identifier = Constants.cellIdentifier
      return view
    }()

    cell.configure(ExtensionsRowView(
      model: model,
      item: displayedItems[row],
      rowMargin: Constants.rowMargin
    ))

    return cell
  }

  func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
    let rowView = tableView.makeView(withIdentifier: Constants.rowIdentifier, owner: self) as? TableRowWrapper ?? {
      let view = TableRowWrapper(horizontalMargin: Constants.rowMargin)
      view.identifier = Constants.rowIdentifier
      return view
    }()

    // Opaque fill so animating rows don't show each other's text through the crossfade
    rowView.backgroundColor = .windowBackgroundColor
    return rowView
  }
}

// MARK: - NSMenuDelegate

extension ExtensionsViewController: NSMenuDelegate {
  func menuNeedsUpdate(_ menu: NSMenu) {
    menu.removeAllItems()

    let clickedRow = tableView.clickedRow
    guard clickedRow >= 0, clickedRow < displayedItems.count else {
      return
    }

    // In Discover, offer a quick uninstall for extensions that are already installed
    let clickedItem = displayedItems[clickedRow]
    guard model.mode == .discover, clickedItem.installed != nil else {
      return
    }

    let item = menu.addItem(
      withTitle: Localized.Extension.uninstall,
      action: #selector(uninstallExtension(_:)),
      keyEquivalent: ""
    )

    item.representedObject = clickedItem.id
    item.target = self
  }
}

// MARK: - ExtensionsPresenting

extension ExtensionsViewController: ExtensionsPresenting {
  func confirmUninstall(name: String) async -> Bool {
    let alert = NSAlert()
    alert.messageText = String(format: Localized.Extension.uninstallConfirmFormat, name)
    alert.informativeText = Localized.Extension.uninstallConfirmMessage
    alert.addButton(withTitle: Localized.Extension.uninstall).hasDestructiveAction = true
    alert.addButton(withTitle: Localized.General.cancel)
    return await presentSheetModal(alert) == .alertFirstButtonReturn
  }

  func reportFailure(_ error: Error) async {
    let alert = NSAlert()
    alert.messageText = Localized.Extension.failedTitle
    alert.informativeText = Localized.Extension.failureMessage(for: error)
    await presentSheetModal(alert)
  }
}

// MARK: - Refresh

extension ExtensionsViewController {
  /// Explicit "Refresh": animate every row out, reconcile and refetch, then animate the fresh rows in.
  func refreshAnimated() {
    runWithProgressOverlay(message: Localized.Extension.refreshing) { [weak self] in
      await self?.model.load(forceRefresh: true)
    }
  }

  func updateAllAnimated() {
    runWithProgressOverlay(message: Localized.Extension.updating) { [weak self] in
      await self?.model.updateAllExtensions()
    }
  }

  /// Scrolls to `category`'s first item; returns whether it scrolled now (else once rows load).
  @discardableResult
  func scrollTo(category: ExtensionEntry.Category) -> Bool {
    pendingScrollCategory = category
    return scrollToTargetCategory()
  }
}

// MARK: - Private

private extension ExtensionsViewController {
  enum Constants {
    static let rowMargin: Double = 20
    static let rowIdentifier = NSUserInterfaceItemIdentifier("ExtensionsRow")
    static let cellIdentifier = NSUserInterfaceItemIdentifier("ExtensionsRowCell")
    static let overScrollInset: Double = if #available(macOS 26.0, *) { 20 } else { 0 }
    static let overlayOpticalOffset: Double = 20
    static let minimumOverlayDuration: TimeInterval = 1.2
  }

  /// Height of the relaunch bar's SwiftUI content (forces a layout pass first).
  var relaunchBarHeight: Double {
    relaunchController.view.needsLayout = true
    relaunchController.view.layoutSubtreeIfNeeded()
    return relaunchController.view.fittingSize.height
  }

  func configureTableView() {
    let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("ExtensionsColumn"))
    column.resizingMask = .autoresizingMask
    tableView.addTableColumn(column)

    tableView.headerView = nil
    tableView.style = .plain
    tableView.backgroundColor = .clear
    tableView.selectionHighlightStyle = .none
    tableView.usesAutomaticRowHeights = true
    tableView.rowHeight = 68
    tableView.intercellSpacing = .zero
    tableView.dataSource = self
    tableView.delegate = self
    tableView.registerForDraggedTypes([.string])
    tableView.setDraggingSourceOperationMask(.move, forLocal: true)

    let menu = NSMenu()
    menu.delegate = self
    tableView.menu = menu

    scrollView.documentView = tableView
    scrollView.automaticallyAdjustsContentInsets = false
    scrollView.hasVerticalScroller = true
    scrollView.drawsBackground = true
    scrollView.backgroundColor = .windowBackgroundColor
    view.addSubview(scrollView)
  }

  func configureAccessoryViews() {
    addChild(relaunchController)
    view.addSubview(relaunchController.view)

    addChild(stateController)
    view.addSubview(stateController.view)
  }

  /// Re-arms observation of the model and applies the latest snapshot to the table.
  func observeModelChanges() {
    withObservationTracking {
      _ = model.mode
      _ = model.items
      _ = model.phase
      _ = model.hasLoadedIndex
      _ = model.pendingRelaunch
    } onChange: { [weak self] in
      Task { @MainActor in
        self?.applyModelChanges()
        self?.observeModelChanges()
      }
    }
  }

  func applyModelChanges() {
    // A whole-page overlay task animates the table itself, ignore the intermediate model changes
    guard !isRunningProgressOverlay else {
      return
    }

    let modeChanged = model.mode != displayedMode
    if modeChanged {
      displayedMode = model.mode
    }

    animateDifference(to: model.items)

    // A mode switch is a fresh list, scroll back to the top
    if modeChanged && !displayedItems.isEmpty {
      tableView.scrollRowToVisible(0)
    }

    scrollToTargetCategory()
    updateRelaunchBar()
    updateStateController()
    view.needsLayout = true
  }

  /// Animates row insertions and removals; surviving rows update themselves in place.
  func animateDifference(to newItems: [ExtensionsModel.Item]) {
    let oldItems = displayedItems
    displayedItems = newItems
    tableView.animateRows(from: oldItems, to: newItems)
  }

  /// Frame-based layout so content imposes no Auto Layout fitting size, keeping the window resizable.
  func layoutContents(animated: Bool = false) {
    let bounds = view.bounds
    let relaunchHeight = displayedRelaunch ? relaunchBarHeight : 0
    let relaunchFrame = CGRect(x: 0, y: 0, width: bounds.width, height: relaunchHeight)

    // The list fills the whole area; the translucent bar overlays its bottom edge
    let scrollFrame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
    let topInset = view.safeAreaInsets.top

    // Bottom inset gives over-scroll room and lets the last row clear the overlay bar
    scrollView.contentInsets = NSEdgeInsets(
      top: topInset,
      left: 0,
      bottom: Constants.overScrollInset + relaunchHeight,
      right: 0
    )

    // Cancel the over-scroll breathing room
    scrollView.scrollerInsets = displayedRelaunch ? NSEdgeInsets(
      top: 0,
      left: 0,
      bottom: -Constants.overScrollInset,
      right: 0
    ) : NSEdgeInsets()

    // Center the state overlay, nudged up by an optical offset. It spans the full width
    // (SwiftUI centers the box) so long messages aren't clipped by a stale, narrower frame.
    let visibleHeight = max(0, bounds.height - topInset - relaunchHeight)
    let stateHeight = stateController.view.fittingSize.height
    let stateFrame = CGRect(
      x: 0,
      y: (relaunchHeight + (visibleHeight - stateHeight) / 2 + Constants.overlayOpticalOffset).rounded(),
      width: bounds.width,
      height: stateHeight
    )

    if animated {
      relaunchController.view.animator().frame = relaunchFrame
      scrollView.animator().frame = scrollFrame
      stateController.view.animator().frame = stateFrame
    } else {
      relaunchController.view.frame = relaunchFrame
      scrollView.frame = scrollFrame
      stateController.view.frame = stateFrame
    }
  }

  /// Shows the relaunch bar once a change is staged, sliding it up from the bottom edge.
  func updateRelaunchBar() {
    guard model.pendingRelaunch && !displayedRelaunch else {
      return
    }

    displayedRelaunch = true
    guard !AppDesign.reduceMotion else {
      layoutContents()
      return
    }

    // Start below the bottom edge, then slide up into place
    let barHeight = relaunchBarHeight
    relaunchController.view.frame = CGRect(x: 0, y: -barHeight, width: view.bounds.width, height: barHeight)
    isAnimatingRelaunch = true

    NSAnimationContext.runAnimationGroup { context in
      context.duration = 0.25
      context.timingFunction = CAMediaTimingFunction(name: .easeOut)
      layoutContents(animated: true)
    } completionHandler: { [weak self] in
      Task { @MainActor in
        self?.isAnimatingRelaunch = false
      }
    }
  }

  func updateStateController() {
    // The state view (loading spinner / empty message) shows only when there are no rows
    stateController.view.isHidden = !displayedItems.isEmpty
  }

  /// Empties the list to reveal the whole-page spinner, runs `action`, then animates the fresh rows in.
  func runWithProgressOverlay(message: String, action: @escaping () async -> Void) {
    guard !isRunningProgressOverlay else {
      return
    }

    isRunningProgressOverlay = true
    model.loadingMessage = message

    let oldItems = displayedItems
    displayedItems = []
    tableView.animateRows(from: oldItems, to: [], removeAnimation: .effectFade)
    updateStateController()

    Task { @MainActor in
      let started = Date()
      await action()

      // Keep the spinner visible long enough to read, regardless of how fast the work finished
      let remaining = Constants.minimumOverlayDuration - Date().timeIntervalSince(started)
      if remaining > 0 {
        try? await Task.sleep(for: .seconds(remaining))
      }

      displayedMode = model.mode
      displayedItems = model.items
      tableView.animateRows(from: [], to: displayedItems)

      updateRelaunchBar()
      updateStateController()

      model.loadingMessage = nil
      model.updateProgress = nil
      isRunningProgressOverlay = false
      view.needsLayout = true
    }
  }

  @discardableResult
  func scrollToTargetCategory() -> Bool {
    guard let category = pendingScrollCategory,
          let index = (displayedItems.firstIndex { $0.category == category }) else {
      return false
    }

    pendingScrollCategory = nil
    tableView.needsLayout = true
    tableView.layoutSubtreeIfNeeded()

    let clip = scrollView.contentView
    let topInset = clip.contentInsets.top
    let bottomInset = clip.contentInsets.bottom
    let minY = -topInset
    let maxY = max(minY, tableView.bounds.height + bottomInset - clip.bounds.height)
    let targetY = min(max(tableView.rect(ofRow: index).minY - topInset, minY), maxY)

    // Pin the theme row to the top (just below the titlebar), clamped to the scrollable range
    clip.scroll(to: CGPoint(x: 0, y: targetY))
    scrollView.reflectScrolledClipView(clip)
    return true
  }

  @objc func uninstallExtension(_ sender: NSMenuItem) {
    guard let id = sender.representedObject as? String, let item = (displayedItems.first { $0.id == id }) else {
      return
    }

    Task {
      await model.uninstallExtension(item)
    }
  }
}
