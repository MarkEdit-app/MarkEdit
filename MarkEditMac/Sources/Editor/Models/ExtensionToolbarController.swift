//
//  ExtensionToolbarController.swift
//  MarkEditMac
//
//  Created by cyan on 11/18/26.
//

import AppKit
import AppKitExtensions
import MarkEditKit
import WebKit

@MainActor
final class ExtensionToolbarController: NSObject, NSMenuDelegate, NSMenuItemValidation {
  nonisolated static let identifierPrefix = "app.markedit.extension-toolbar."
  private weak var group: NSToolbarItemGroup?
  private weak var editor: EditorViewController?
  private let entries: [WebToolbarSegment]
  private var revision = 0
  private var actionGeneration = 0
  private var needsRefresh = true
  private var refreshScheduled = false
  private var isRefreshing = false
  private var refreshWaiters = [CheckedContinuation<Void, Never>]()
  private var reportedFailure = false
  private var confirmedSelection = -1
  private var pendingSelection: Int?
  private var menuItems = [NSMenuItem]()
  private var customizationObservation: NSKeyValueObservation?

  nonisolated static func identifier(for id: String) -> NSToolbarItem.Identifier {
    .init(identifierPrefix + id)
  }

  static func makeToolbarItem(spec: WebToolbarItem, editor: EditorViewController) -> NSToolbarItemGroup? {
    let group = NSToolbarItemGroup(
      itemIdentifier: identifier(for: spec.id),
      images: spec.segments.compactMap { editor.createMenuIcon($0.icon) },
      selectionMode: .selectOne,
      labels: nil,
      target: nil,
      action: nil
    )

    return configure(group, spec: spec, editor: editor) ? group : nil
  }

  static func makePlaceholder(identifier: NSToolbarItem.Identifier) -> NSToolbarItemGroup {
    let group = NSToolbarItemGroup(
      itemIdentifier: identifier,
      images: [],
      selectionMode: .selectOne,
      labels: nil,
      target: nil,
      action: nil
    )

    group.label = String(identifier.rawValue.dropFirst(identifierPrefix.count))
    group.isEnabled = false
    return group
  }

  static func isValid(_ spec: WebToolbarItem, editor: EditorViewController) -> Bool {
    guard !spec.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
          !spec.title.isEmpty, editor.createMenuIcon(spec.icon) != nil else {
      return false
    }

    return !spec.segments.isEmpty && spec.segments.allSatisfy {
      !$0.title.isEmpty &&
      !$0.actionID.isEmpty &&
      !$0.stateGetterID.isEmpty &&
      editor.createMenuIcon($0.icon) != nil
    }
  }

  @discardableResult
  static func configure(_ group: NSToolbarItemGroup, spec: WebToolbarItem, editor: EditorViewController) -> Bool {
    guard isValid(spec, editor: editor) else {
      Logger.log(.error, "Invalid toolbar item: \(spec.id)")
      return false
    }

    if group.subitems.isEmpty {
      group.subitems = spec.segments.enumerated().map { index, segment in
        let item = NSToolbarItem(itemIdentifier: .init("\(group.itemIdentifier.rawValue).\(index)"))
        item.image = editor.createMenuIcon(segment.icon)
        return item
      }
    }

    if #available(macOS 27.0, *) {
      group.role = .tabs
    }

    group.controlRepresentation = .expanded
    group.label = spec.title
    group.paletteLabel = spec.title
    group.toolTip = spec.title
    group.image = editor.createMenuIcon(spec.icon)
    group.autovalidates = false
    group.isEnabled = true

    let controller = ExtensionToolbarController(group: group, entries: spec.segments, editor: editor)
    group.extensionToolbarController = controller

    if let toolbar = group.toolbar {
      controller.didInsert(into: toolbar)
    }

    return true
  }

  private init(group: NSToolbarItemGroup, entries: [WebToolbarSegment], editor: EditorViewController) {
    self.group = group
    self.entries = entries
    self.editor = editor
    super.init()

    group.addAction { [weak self] in
      self?.activate(self?.group?.selectedIndex ?? -1)
    }

    menuItems = entries.enumerated().map { index, entry in
      let menuItem = NSMenuItem(title: entry.title)
      menuItem.image = editor.createMenuIcon(entry.icon)
      menuItem.tag = index
      menuItem.target = self
      menuItem.action = #selector(menuAction(_:))
      return menuItem
    }

    for (index, subitem) in group.subitems.enumerated() {
      subitem.label = entries[index].title
      subitem.image = menuItems[index].image
      subitem.toolTip = entries[index].title
      subitem.autovalidates = false
      subitem.addAction { [weak self] in
        self?.activate(index)
      }
    }

    let menu = NSMenu()
    menu.autoenablesItems = false
    menu.delegate = self
    menu.items = menuItems

    let representation = NSMenuItem(title: group.label)
    representation.image = group.image
    representation.ensureImageVisibility()
    representation.submenu = menu
    group.menuFormRepresentation = representation
    updateSelection()

    for index in entries.indices {
      setEnabled(false, at: index)
    }

    scheduleRefresh()
  }
}

extension ExtensionToolbarController {
  func didInsert(into toolbar: NSToolbar) {
    invalidateState()
    customizationObservation = toolbar.observe(\.customizationPaletteIsRunning, options: .new) { [weak self] _, change in
      guard change.newValue == false else {
        return
      }

      Task { @MainActor [weak self] in
        self?.invalidateState()
      }
    }
  }

  func invalidateState() {
    revision += 1
    needsRefresh = true
    scheduleRefresh()
  }

  func menuNeedsUpdate(_ menu: NSMenu) {
    // AppKit can copy the menu. Use cached state without waiting inside menu tracking
    for item in menu.items where menuItems.indices.contains(item.tag) {
      item.isEnabled = menuItems[item.tag].isEnabled
      item.state = menuItems[item.tag].state
    }
  }

  func menuDidClose(_ menu: NSMenu) {
    Task { [weak self] in
      await self?.refreshState()
    }
  }

  func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    menuItems.indices.contains(menuItem.tag) && menuItems[menuItem.tag].isEnabled
  }

  func refreshState(forceFresh: Bool = false) async {
    guard pendingSelection == nil, let editor, let group else {
      return
    }

    if isRefreshing {
      await withCheckedContinuation {
        refreshWaiters.append($0)
      }

      if forceFresh || needsRefresh {
        await refreshState()
      }

      return
    }

    let ids = entries.map(\.stateGetterID)
    isRefreshing = true
    needsRefresh = false

    let requestedRevision = revision
    defer {
      isRefreshing = false
      refreshWaiters.forEach { $0.resume() }
      refreshWaiters.removeAll()
      scheduleRefresh()
    }

    do {
      let states = try await editor.bridge.api.getMenuItemStates(ids: ids)
      guard requestedRevision == revision else {
        return
      }

      guard states.count == entries.count else {
        throw WKWebView.InvokeError.decodeError
      }

      let selected = states.indices.filter {
        states[$0].isSelected == true
      }

      for (index, state) in states.enumerated() {
        setEnabled(state.isEnabled ?? true, at: index)
      }

      confirmedSelection = selected.count == 1 ? selected[0] : -1
      updateSelection()

      if selected.count > 1 {
        if !reportedFailure {
          Logger.log(.error, "Multiple selected toolbar segments: \(group.label)")
        }

        reportedFailure = true
      } else {
        reportedFailure = false
      }
    } catch {
      guard requestedRevision == revision else {
        return
      }

      for index in entries.indices {
        setEnabled(false, at: index)
      }

      confirmedSelection = -1
      updateSelection()
      if !reportedFailure {
        Logger.log(.error, "Failed to refresh toolbar item \(group.label): \(error)")
      }

      reportedFailure = true
    }
  }
}

extension NSToolbarItem {
  private enum AssociatedObjects {
    static var extensionToolbarController = false
  }

  var extensionToolbarController: ExtensionToolbarController? {
    get {
      objc_getAssociatedObject(
        self,
        &AssociatedObjects.extensionToolbarController
      ) as? ExtensionToolbarController
    }
    set {
      objc_setAssociatedObject(
        self,
        &AssociatedObjects.extensionToolbarController,
        newValue,
        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
    }
  }
}

// MARK: - Private

private extension ExtensionToolbarController {
  func activate(_ index: Int) {
    guard entries.indices.contains(index), menuItems[index].isEnabled, let editor else {
      updateSelection()
      return
    }

    revision += 1
    actionGeneration += 1

    let actionRevision = actionGeneration
    needsRefresh = true
    pendingSelection = index
    updateSelection()

    editor.bridge.api.handleMainMenuAction(id: entries[index].actionID) { [weak self] result in
      if case let .failure(error) = result {
        Logger.log(.error, "Failed toolbar action: \(error)")
      }

      guard let self, actionGeneration == actionRevision else {
        return
      }

      pendingSelection = nil
      if case .failure = result {
        updateSelection()
      }

      scheduleRefresh()
    }
  }

  func scheduleRefresh() {
    guard needsRefresh, !isRefreshing, !refreshScheduled, pendingSelection == nil else {
      return
    }

    refreshScheduled = true
    Task { [weak self] in
      guard let self else {
        return
      }

      refreshScheduled = false
      if needsRefresh {
        await refreshState()
      }
    }
  }

  @objc func menuAction(_ sender: NSMenuItem) {
    let actionRevision = actionGeneration
    Task {
      await refreshState(forceFresh: true)
      guard actionGeneration == actionRevision, pendingSelection == nil, !needsRefresh, !isRefreshing else {
        return
      }

      activate(sender.tag)
    }
  }

  func setEnabled(_ enabled: Bool, at index: Int) {
    group?.subitems[index].isEnabled = enabled
    menuItems[index].isEnabled = enabled
  }

  func updateSelection() {
    guard let group else {
      return
    }

    let selection = pendingSelection ?? confirmedSelection
    for (index, menuItem) in menuItems.enumerated() {
      menuItem.setOn(index == selection)
    }

    guard !entries.indices.allSatisfy({ group.isSelected(at: $0) == ($0 == selection) }) else {
      return
    }

    if selection >= 0 {
      group.setSelected(true, at: selection)
      return
    }

    // AppKit's selectOne mode refuses to deselect its last selected item
    group.selectionMode = .selectAny
    for index in entries.indices where group.isSelected(at: index) {
      group.setSelected(false, at: index)
    }

    group.selectionMode = .selectOne
  }
}
