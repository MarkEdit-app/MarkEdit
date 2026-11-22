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

/// Default appearance only; callbacks, live state, and placement decisions stay with the editor.
struct ToolbarItemDefaults: Codable, Equatable, Sendable {
  let type: WebToolbarItemMembersTypeType
  let title: String
  let icon: String
  let items: [Item]

  init(_ spec: WebToolbarItem) {
    type = spec.type
    title = spec.title
    icon = spec.icon

    if spec.type == .group {
      items = (spec.children ?? []).map {
        Item(title: $0.title ?? "", icon: $0.icon ?? "")
      }
    } else {
      items = spec.segments?.map {
        Item(title: $0.title, icon: $0.icon)
      } ?? []
    }
  }

  struct Item: Codable, Equatable, Sendable {
    let title: String
    let icon: String
  }
}

@MainActor
final class ExtensionToolbarController: NSObject, NSMenuDelegate, NSMenuItemValidation {
  typealias Kind = WebToolbarItemMembersTypeType

  static var cachedDefaults = AppPreferences.Window.extensionToolbarCache
  nonisolated private static let identifierPrefix = "app.markedit.extension-toolbar."

  private weak var item: NSToolbarItem?
  private weak var editor: EditorViewController?
  private var group: NSToolbarItemGroup? { item as? NSToolbarItemGroup }
  private let defaults: ToolbarItemDefaults
  private var appliedIcons: [String]
  private var entries = [Entry]()
  private var revision = 0
  private var actionGeneration = 0
  private var needsRefresh = true
  private var refreshScheduled = false
  private var isRefreshing = false
  private var refreshWaiters = [CheckedContinuation<Void, Never>]()
  private var reportedFailure = false
  private var confirmedSelection = -1
  private var pendingAction: Int?
  private var customizationObservation: NSKeyValueObservation?

  private init(item: NSToolbarItem, defaults: ToolbarItemDefaults, editor: EditorViewController) {
    self.item = item
    self.editor = editor
    self.defaults = defaults
    appliedIcons = defaults.type == .group ? defaults.items.map(\.icon) : [defaults.icon]

    super.init()
  }
}

extension ExtensionToolbarController {
  nonisolated static func identifier(for id: String) -> NSToolbarItem.Identifier {
    .init(identifierPrefix + id)
  }

  nonisolated static func id(for identifier: NSToolbarItem.Identifier) -> String? {
    guard identifier.rawValue.hasPrefix(identifierPrefix) else {
      return nil
    }

    return String(identifier.rawValue.dropFirst(identifierPrefix.count))
  }

  static func cacheDefaults(_ specs: [WebToolbarItem]) {
    guard !AppCustomization.isSafeMode else {
      return
    }

    var changed = false
    for spec in specs {
      let defaults = ToolbarItemDefaults(spec)
      guard cachedDefaults[spec.id] != defaults else {
        continue
      }

      cachedDefaults[spec.id] = defaults
      changed = true
    }

    if changed {
      AppPreferences.Window.extensionToolbarCache = cachedDefaults
    }
  }

  static func makeToolbarItem(spec: WebToolbarItem, editor: EditorViewController) -> NSToolbarItem? {
    let item = makeItem(
      identifier: identifier(for: spec.id),
      kind: spec.type,
      images: spec.segments?.compactMap { editor.createMenuIcon($0.icon) } ?? []
    )

    return configure(item, spec: spec, editor: editor) ? item : nil
  }

  static func makeCachedToolbarItem(
    identifier: NSToolbarItem.Identifier,
    editor: EditorViewController
  ) -> NSToolbarItem? {
    guard !AppCustomization.isSafeMode,
          let id = id(for: identifier), let defaults = cachedDefaults[id] else {
      return nil
    }

    let item = makeItem(
      identifier: identifier,
      kind: defaults.type,
      images: defaults.items.compactMap { editor.createMenuIcon($0.icon) }
    )

    guard applyDefaults(defaults, to: item, editor: editor) else {
      cachedDefaults.removeValue(forKey: id)
      return nil
    }

    if let menuItem = item as? NSMenuToolbarItem {
      menuItem.menu = NSMenu()
    }

    let representation = NSMenuItem(title: defaults.title)
    representation.image = item.image
    representation.ensureImageVisibility()
    representation.isEnabled = false

    if defaults.type != .button {
      representation.submenu = NSMenu()
    }

    item.menuFormRepresentation = representation
    item.isEnabled = false

    (item as? NSToolbarItemGroup)?.subitems.forEach {
      $0.isEnabled = false
    }

    return item
  }

  static func makePlaceholder(identifier: NSToolbarItem.Identifier) -> NSToolbarItem? {
    guard let id = id(for: identifier) else {
      Logger.log(.error, "Unknown extension toolbar identifier: \(identifier.rawValue)")
      return nil
    }

    let item = NSToolbarItem(itemIdentifier: identifier)
    item.label = id
    item.autovalidates = false
    item.isEnabled = false
    return item
  }

  static func isValid(_ spec: WebToolbarItem, editor: EditorViewController) -> Bool {
    guard !spec.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
          !spec.title.isEmpty, editor.createMenuIcon(spec.icon) != nil else {
      return false
    }

    switch spec.type {
    case .button:
      return spec.actionID?.isEmpty == false
    case .menu:
      return spec.children != nil
    case .segmented:
      guard let segments = spec.segments, !segments.isEmpty else {
        return false
      }

      return segments.allSatisfy {
        !$0.title.isEmpty &&
        !$0.actionID.isEmpty &&
        !$0.stateGetterID.isEmpty &&
        editor.createMenuIcon($0.icon) != nil
      }
    case .group:
      guard let children = spec.children, !children.isEmpty else {
        return false
      }

      return children.allSatisfy {
        !$0.separator && $0.children == nil &&
        $0.title?.isEmpty == false && $0.actionID?.isEmpty == false &&
        $0.icon.flatMap { editor.createMenuIcon($0) } != nil
      }
    }
  }

  static func matches(_ item: NSToolbarItem, spec: WebToolbarItem) -> Bool {
    switch spec.type {
    case .button: return !(item is NSMenuToolbarItem) && !(item is NSToolbarItemGroup)
    case .menu: return item is NSMenuToolbarItem
    case .segmented, .group:
      guard let group = item as? NSToolbarItemGroup else {
        return false
      }

      guard (group is ActionToolbarItemGroup) == (spec.type == .group) else {
        return false
      }

      let count = spec.type == .group ? spec.children?.count : spec.segments?.count
      return group.subitems.isEmpty || group.subitems.count == count
    }
  }

  @discardableResult
  static func configure(
    _ item: NSToolbarItem,
    spec: WebToolbarItem,
    editor: EditorViewController
  ) -> Bool {
    guard isValid(spec, editor: editor), matches(item, spec: spec) else {
      Logger.log(.error, "Invalid toolbar item: \(spec.id)")
      return false
    }

    guard applyDefaults(ToolbarItemDefaults(spec), to: item, editor: editor) else {
      return false
    }

    item.isEnabled = false
    let controller = ExtensionToolbarController(item: item, spec: spec, editor: editor)
    item.extensionToolbarController = controller

    if let toolbar = item.toolbar {
      controller.didInsert(into: toolbar)
    }

    return true
  }
}

private extension ExtensionToolbarController {
  convenience init(item: NSToolbarItem, spec: WebToolbarItem, editor: EditorViewController) {
    self.init(item: item, defaults: ToolbarItemDefaults(spec), editor: editor)
    bindActions(spec: spec, item: item, editor: editor)
  }

  func bindActions(spec: WebToolbarItem, item: NSToolbarItem, editor: EditorViewController) {
    let children = spec.segments?.map {
      WebMenuItem(
        separator: false,
        title: $0.title,
        icon: $0.icon,
        actionID: $0.actionID,
        stateGetterID: $0.stateGetterID,
        key: nil,
        modifiers: nil,
        children: nil
      )
    } ?? spec.children

    let menuSpec = WebMenuItem(
      separator: false,
      title: spec.title,
      icon: spec.icon,
      actionID: spec.actionID,
      stateGetterID: spec.stateGetterID,
      key: nil,
      modifiers: nil,
      children: children
    )

    let representation = editor.createMenuItem(spec: menuSpec) { [weak self] actionID, _ in
      self?.menuAction(actionID)
    }

    if let group, let submenu = representation.submenu, let children {
      bind(submenu, specs: children, parent: nil)
      if spec.type == .segmented {
        group.addAction { [weak self] in
          self?.activate(self?.group?.selectedIndex ?? -1)
        }
      }

      for (index, subitem) in group.subitems.enumerated() {
        if spec.type == .group {
          subitem.menuFormRepresentation = entries[index].menuItem
        }

        subitem.addAction { [weak self] in
          self?.activate(index)
        }
      }
    } else {
      bind(representation, spec: menuSpec, parent: nil)
      if let menuItem = item as? NSMenuToolbarItem, let submenu = representation.submenu {
        menuItem.menu = submenu
      } else {
        item.addAction { [weak self] in
          self?.activate(0)
        }
      }
    }

    representation.image = item.image
    representation.ensureImageVisibility()
    item.menuFormRepresentation = representation
    updateSelection()

    for index in entries.indices {
      setEnabled(false, at: index)
    }

    scheduleRefresh()
  }

  private struct Entry {
    let menuItem: NSMenuItem
    let actionID: String?
    let stateGetterID: String?
    let parent: Int?
  }

  private enum StateError: Error {
    case invalidIcon
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
    for item in menu.items where !item.isSeparatorItem && entries.indices.contains(item.tag) {
      let source = entries[item.tag].menuItem
      item.isEnabled = source.isEnabled
      item.state = source.state

      if item.title != source.title {
        item.title = source.title
        item.attributedTitle = source.attributedTitle
      }

      if item.image !== source.image {
        item.image = source.image
      }
    }
  }

  func menuDidClose(_ menu: NSMenu) {
    Task { [weak self] in
      await self?.refreshState()
    }
  }

  func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    entries.indices.contains(menuItem.tag) && entries[menuItem.tag].menuItem.isEnabled
  }

  func refreshState(forceFresh: Bool = false) async {
    guard pendingAction == nil, let editor, let item else {
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

    let ids = entries.compactMap(\.stateGetterID)
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
      let states = ids.isEmpty ? [] : try await editor.bridge.api.getMenuItemStates(ids: ids)
      guard requestedRevision == revision else {
        return
      }

      guard states.count == ids.count else {
        throw WKWebView.InvokeError.decodeError
      }

      var stateIterator = states.makeIterator()
      for (index, entry) in entries.enumerated() {
        let state = entry.stateGetterID == nil ? nil : stateIterator.next()
        if defaults.type == .group || (index == 0 && group == nil) {
          try updateAppearance(state, at: index, editor: editor)
        }

        let parentEnabled = entry.parent.map { entries[$0].menuItem.isEnabled } ?? true
        setEnabled(parentEnabled && (state?.isEnabled ?? true), at: index)
        entry.menuItem.setOn(defaults.type != .group && (state?.isSelected ?? false))
      }

      if let group, !group.isEnabled {
        group.isEnabled = true
      }

      updateConfirmedSelection()
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
        Logger.log(.error, "Failed to refresh toolbar item \(item.label): \(error)")
      }

      reportedFailure = true
    }
  }
}

extension NSToolbarItem {
  private enum AssociatedObjects {
    static var extensionToolbarController = false
    static var extensionToolbarDefaults = false
  }

  var extensionToolbarDefaults: ToolbarItemDefaults? {
    get {
      objc_getAssociatedObject(
        self,
        &AssociatedObjects.extensionToolbarDefaults
      ) as? ToolbarItemDefaults
    }
    set {
      objc_setAssociatedObject(
        self,
        &AssociatedObjects.extensionToolbarDefaults,
        newValue,
        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
    }
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
  static func applyDefaults(
    _ defaults: ToolbarItemDefaults,
    to item: NSToolbarItem,
    editor: EditorViewController
  ) -> Bool {
    guard item.extensionToolbarDefaults != defaults else {
      return true
    }

    guard !defaults.title.isEmpty, let image = editor.createMenuIcon(defaults.icon) else {
      Logger.log(.error, "Invalid toolbar defaults: \(item.itemIdentifier.rawValue)")
      return false
    }

    if let group = item as? NSToolbarItemGroup {
      let images = defaults.items.compactMap { editor.createMenuIcon($0.icon) }
      guard !images.isEmpty, images.count == defaults.items.count else {
        Logger.log(.error, "Invalid toolbar subitem defaults: \(item.itemIdentifier.rawValue)")
        return false
      }

      if group.subitems.isEmpty {
        group.subitems = defaults.items.indices.map {
          NSToolbarItem(itemIdentifier: .init("\(group.itemIdentifier.rawValue).\($0)"))
        }
      }

      guard group.subitems.count == images.count else {
        Logger.log(.error, "Mismatched toolbar subitem defaults: \(item.itemIdentifier.rawValue)")
        return false
      }

      if #available(macOS 27.0, *), defaults.type == .segmented {
        group.role = .tabs
      }

      group.controlRepresentation = .expanded
      for (index, subitem) in group.subitems.enumerated() {
        subitem.label = defaults.items[index].title
        subitem.paletteLabel = subitem.label
        subitem.toolTip = subitem.label
        subitem.image = images[index]
        subitem.autovalidates = false
        subitem.isBordered = true
      }
    }

    item.label = defaults.title
    item.paletteLabel = defaults.title
    item.toolTip = defaults.title
    item.image = image
    item.autovalidates = false
    item.extensionToolbarDefaults = defaults
    return true
  }

  static func makeItem(identifier: NSToolbarItem.Identifier, kind: Kind, images: [NSImage] = []) -> NSToolbarItem {
    switch kind {
    case .button:
      return NSToolbarItem(itemIdentifier: identifier)
    case .menu:
      return NSMenuToolbarItem(itemIdentifier: identifier)
    case .segmented:
      return NSToolbarItemGroup(
        itemIdentifier: identifier,
        images: images,
        selectionMode: .selectOne,
        labels: nil,
        target: nil,
        action: nil
      )
    case .group:
      return ActionToolbarItemGroup(itemIdentifier: identifier)
    }
  }

  func bind(_ menuItem: NSMenuItem, spec: WebMenuItem, parent: Int?) {
    guard !spec.separator else {
      return
    }

    let index = entries.count
    menuItem.tag = index

    entries.append(Entry(
      menuItem: menuItem,
      actionID: spec.actionID,
      stateGetterID: spec.stateGetterID,
      parent: parent
    ))

    if let submenu = menuItem.submenu, let children = spec.children {
      bind(submenu, specs: children, parent: index)
    }
  }

  func bind(_ menu: NSMenu, specs: [WebMenuItem], parent: Int?) {
    menu.autoenablesItems = false
    menu.delegate = self

    for (item, spec) in zip(menu.items, specs) {
      bind(item, spec: spec, parent: parent)
    }
  }

  func activate(_ index: Int) {
    guard entries.indices.contains(index), entries[index].menuItem.isEnabled,
          let actionID = entries[index].actionID, let editor else {
      updateSelection()
      return
    }

    revision += 1
    actionGeneration += 1

    let actionRevision = actionGeneration
    needsRefresh = true
    pendingAction = index
    updateSelection()

    editor.bridge.api.handleMainMenuAction(id: actionID) { [weak self] result in
      if case let .failure(error) = result {
        Logger.log(.error, "Failed toolbar action: \(error)")
      }

      guard let self, actionGeneration == actionRevision else {
        return
      }

      pendingAction = nil
      if case .failure = result {
        updateSelection()
      }

      scheduleRefresh()
    }
  }

  func scheduleRefresh() {
    guard needsRefresh, !isRefreshing, !refreshScheduled, pendingAction == nil else {
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

  func menuAction(_ actionID: String) {
    guard let index = (entries.firstIndex { $0.actionID == actionID }) else {
      return Logger.assertFail("Missing toolbar action: \(actionID)")
    }

    let actionRevision = actionGeneration
    Task {
      await refreshState(forceFresh: true)
      guard actionGeneration == actionRevision, pendingAction == nil, !needsRefresh, !isRefreshing else {
        return
      }

      activate(index)
    }
  }

  func setEnabled(_ enabled: Bool, at index: Int) {
    if let group {
      group.subitems[index].isEnabled = enabled
    } else if index == 0 {
      item?.isEnabled = enabled
    }

    entries[index].menuItem.isEnabled = enabled
  }

  func updateAppearance(_ state: WebToolbarItemState?, at index: Int, editor: EditorViewController) throws {
    guard let item = defaults.type == .group ? group?.subitems[index] : item else {
      return
    }

    let title = state?.title ?? (defaults.type == .group ? defaults.items[index].title : defaults.title)
    let icon = state?.icon ?? (defaults.type == .group ? defaults.items[index].icon : defaults.icon)
    let representation = defaults.type == .group ? entries[index].menuItem : item.menuFormRepresentation
    let image: NSImage?
    if icon != appliedIcons[index] {
      guard let resolved = editor.createMenuIcon(icon) else {
        throw StateError.invalidIcon
      }

      image = resolved
    } else {
      image = nil
    }

    if item.label != title {
      item.label = title
      item.paletteLabel = title
      item.toolTip = title

      if let representation {
        representation.title = title
        representation.attributedTitle = nil
        representation.ensureTitleVisibility()
      }
    }

    if let image {
      item.image = image
      representation?.image = image
      appliedIcons[index] = icon
    }
  }

  func updateConfirmedSelection() {
    guard defaults.type == .segmented else {
      reportedFailure = false
      return
    }

    let selected = entries.indices.filter { entries[$0].menuItem.state == .on }
    confirmedSelection = selected.count == 1 ? selected[0] : -1
    updateSelection()

    if selected.count > 1 && !reportedFailure {
      Logger.log(.error, "Multiple selected toolbar segments: \(self.item?.label ?? "")")
    }

    reportedFailure = selected.count > 1
  }

  func updateSelection() {
    guard defaults.type == .segmented, let group else {
      return
    }

    let selection = pendingAction ?? confirmedSelection
    for (index, entry) in entries.enumerated() {
      entry.menuItem.setOn(index == selection)
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

private final class ActionToolbarItemGroup: NSToolbarItemGroup {
  override init(itemIdentifier: NSToolbarItem.Identifier) {
    super.init(itemIdentifier: itemIdentifier)
    selectionMode = .momentary
  }
}
