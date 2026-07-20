//
//  ExtensionsWindowController.swift
//  MarkEditMac
//
//  Created by cyan on 7/13/26.
//

import AppKit
import AppKitExtensions
import ExtensionCore

/// Hosts the Extension Manager: an AppKit window and toolbar wrapping the extension list.
@MainActor
final class ExtensionsWindowController: NSWindowController {
  static let shared = ExtensionsWindowController.createController()
  private let model = ExtensionsModel()
  private weak var modeControl: NSSegmentedControl?
  private weak var updateAllItem: NSMenuItem?
  private weak var updateBehaviorMenu: NSMenu?

  func present(scrollTo category: ExtensionEntry.Category? = nil) {
    if !AppPreferences.Extensions.windowHasBeenOpened {
      AppPreferences.Extensions.windowHasBeenOpened = true
      ExtensionUpdater.requestMenuUpdate()
    }

    if category != nil {
      model.mode = .discover
      updateModeControl()
    }

    showWindow(nil)
    window?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)

    var scrolledToCategory = false
    if let category {
      scrolledToCategory = extensionsVC?.scrollTo(category: category) ?? false
    }

    Task {
      // Fetch fresh every time the window opens; the conditional GET is cheap
      // and falls back to the cache when offline or unchanged.
      await model.load(forceRefresh: true)

      // Re-request if it wasn't listed initially
      if let category, !scrolledToCategory {
        extensionsVC?.scrollTo(category: category)
      }
    }
  }

  // MARK: - Disable external init

  override private init(window: NSWindow?) {
    super.init(window: window)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: - Responder Chain

extension ExtensionsWindowController {
  // The main menu binds "Select All" to `selectWholeDocument(_:)`
  @IBAction func selectWholeDocument(_ sender: Any?) {
    NSApp.sendAction(#selector(NSResponder.selectAll(_:)), to: nil, from: sender)
  }

  // The main menu binds "Find" (Cmd-F) to `startFind(_:)`; focus the toolbar search field
  @IBAction func startFind(_ sender: Any?) {
    searchToolbarItem?.beginSearchInteraction()
  }
}

// MARK: - NSMenuDelegate

extension ExtensionsWindowController: NSMenuDelegate {
  func menuNeedsUpdate(_ menu: NSMenu) {
    let count = model.availableUpdateCount
    updateAllItem?.isEnabled = count > 0
    updateAllItem?.title = count > 0 ? "\(Localized.Extension.updateAll) (\(count))" : Localized.Extension.updateAll
    refreshUpdateSettingChecks()
  }
}

// MARK: - NSToolbarDelegate

extension ExtensionsWindowController: NSToolbarDelegate {
  func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    [.mode, .actions, .search]
  }

  func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    toolbarDefaultItemIdentifiers(toolbar)
  }

  func toolbar(
    _ toolbar: NSToolbar,
    itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
    willBeInsertedIntoToolbar flag: Bool
  ) -> NSToolbarItem? {
    switch itemIdentifier {
    case .mode:
      return createModeItem()
    case .search:
      let item = NSSearchToolbarItem(itemIdentifier: .search)
      item.minimumSearchFieldWidth = 220 // Easier to collapse by default
      item.searchField.placeholderString = Localized.Extension.searchPlaceholder
      item.searchField.target = self
      item.searchField.action = #selector(handleSearchChange(_:))
      item.searchField.delegate = self
      return item
    case .actions:
      let item = NSMenuToolbarItem(itemIdentifier: .actions)
      item.visibilityPriority = .high
      item.image = NSImage(systemSymbolName: Icons.ellipsisCircle, accessibilityDescription: nil)
      item.label = Localized.Extension.actions
      item.toolTip = Localized.Extension.actions
      item.menu = createActionsMenu()
      return item
    default:
      return nil
    }
  }
}

// MARK: - NSSearchFieldDelegate

extension ExtensionsWindowController: NSSearchFieldDelegate {
  func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
    guard selector == #selector(cancelOperation(_:)) else {
      return false
    }

    // Esc clears the query and collapses the search field
    control.stringValue = ""
    model.searchQuery = ""
    searchToolbarItem?.endSearchInteraction()
    return true
  }
}

// MARK: - Private

private extension ExtensionsWindowController {
  enum Constants {
    static let contributingURL = "https://github.com/MarkEdit-app/extensions#contributing"
  }

  var extensionsVC: ExtensionsViewController? {
    window?.contentViewController as? ExtensionsViewController
  }

  var searchToolbarItem: NSSearchToolbarItem? {
    window?.toolbar?.items.first { $0.itemIdentifier == .search } as? NSSearchToolbarItem
  }

  static func createController() -> ExtensionsWindowController {
    let window = NSWindow(
      contentRect: ExtensionsViewController.defaultContentRect,
      styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
      backing: .buffered,
      defer: false
    )

    window.title = Localized.Extension.windowTitle
    window.contentMinSize = CGSize(width: 480, height: 200)
    window.isReleasedWhenClosed = false

    let controller = Self(window: window)
    controller.model.primeFromCache()
    controller.configureToolbar()

    NotificationCenter.default.addObserver(
      controller,
      selector: #selector(handleExtensionsChange(_:)),
      name: .extensionsMenuNeedsUpdate,
      object: nil
    )

    window.contentViewController = ExtensionsViewController(model: controller.model)
    window.center()
    return controller
  }

  func configureToolbar() {
    let toolbar = NSToolbar(identifier: "ExtensionsToolbar")
    toolbar.displayMode = .iconOnly
    toolbar.allowsUserCustomization = false
    toolbar.allowsDisplayModeCustomization = false
    toolbar.delegate = self

    window?.toolbar = toolbar
    window?.toolbarStyle = .unified
  }

  func createModeItem() -> NSToolbarItem {
    let segmented = NSSegmentedControl(
      labels: [Localized.Extension.discover, Localized.Extension.installed],
      trackingMode: .selectOne,
      target: self,
      action: #selector(handleModeChange(_:))
    )

    segmented.setSymbolImages([Icons.sparkles, Icons.shippingbox])
    modeControl = segmented
    updateModeControl()

    let item = NSToolbarItem(itemIdentifier: .mode)
    item.visibilityPriority = .high
    item.view = segmented
    item.label = Localized.Extension.windowTitle

    return item
  }

  func createActionsMenu() -> NSMenu {
    let menu = NSMenu()
    menu.autoenablesItems = false
    menu.delegate = self

    menu.addItem(withTitle: Localized.Extension.refresh) { [weak self] in
      self?.extensionsVC?.refreshAnimated()
    }

    updateAllItem = menu.addItem(withTitle: Localized.Extension.updateAll) { [weak self] in
      self?.extensionsVC?.updateAllAnimated()
    }

    let updateBehaviorItem = NSMenuItem()
    updateBehaviorItem.title = Localized.Extension.updateBehavior
    updateBehaviorItem.submenu = createUpdateBehaviorMenu()
    updateBehaviorMenu = updateBehaviorItem.submenu
    menu.addItem(updateBehaviorItem)

    menu.addItem(.separator())
    menu.addItem(
      withTitle: Localized.Extension.installFromURL,
      action: #selector(promptInstallFromURL)
    )

    menu.addItem(withTitle: Localized.Extension.openScriptsFolder) { [weak self] in
      self?.model.openScriptsFolder()
    }

    menu.addItem(.separator())
    menu.addItem(withTitle: Localized.Extension.submitExtension) {
      NSWorkspace.shared.safelyOpenURL(string: Constants.contributingURL)
    }

    return menu
  }

  func createUpdateBehaviorMenu() -> NSMenu {
    let menu = NSMenu()
    let options: [(ExtensionConfig.UpdateBehavior, String)] = [
      (.never, Localized.Extension.behaviorNever),
      (.quiet, Localized.Extension.behaviorQuiet),
      (.notify, Localized.Extension.behaviorNotify),
      (.automatic, Localized.Extension.behaviorAutomatic),
    ]

    for (value, title) in options {
      let item = menu.addItem(withTitle: title) { [weak self] in
        ExtensionConfig.setUpdateBehavior(value)
        self?.refreshUpdateSettingChecks()
      }

      item.representedObject = value.rawValue
    }

    return menu
  }

  func updateModeControl() {
    modeControl?.selectedSegment = model.mode == .discover ? 0 : 1
    modeControl?.setToolTip(Localized.Extension.itemCount(model.discoverCount), forSegment: 0)
    modeControl?.setToolTip(Localized.Extension.itemCount(model.installedCount), forSegment: 1)
  }

  /// Checks the option matching the persisted update behavior.
  func refreshUpdateSettingChecks() {
    let behavior = ExtensionConfig.updateBehavior.rawValue
    updateBehaviorMenu?.items.forEach {
      $0.state = ($0.representedObject as? String) == behavior ? .on : .off
    }
  }

  @objc func handleModeChange(_ sender: NSSegmentedControl) {
    model.mode = sender.selectedSegment == 0 ? .discover : .installed
  }

  @objc func handleSearchChange(_ sender: NSSearchField) {
    model.searchQuery = sender.stringValue
  }

  @objc func handleExtensionsChange(_ notification: Notification) {
    updateModeControl()
  }

  @objc func promptInstallFromURL() {
    let alert = NSAlert()
    alert.messageText = Localized.Extension.installFromURLTitle
    alert.addButton(withTitle: Localized.Extension.installButton)
    alert.addButton(withTitle: Localized.General.cancel)

    let textField = NSTextField.alertCapableTextField
    textField.placeholderString = "https://"
    alert.accessoryView = textField
    alert.window.initialFirstResponder = textField

    Task {
      guard let window else {
        return
      }

      guard await alert.beginSheetModal(for: window) == .alertFirstButtonReturn else {
        return
      }

      guard let url = URL(string: textField.stringValue), url.scheme?.isEmpty == false else {
        return
      }

      await model.installExtension(from: url)
    }
  }
}

// MARK: - Toolbar Identifiers

private extension NSToolbarItem.Identifier {
  static let mode = Self("app.markedit.extension.mode")
  static let actions = Self("app.markedit.extension.actions")
  static let search = Self("app.markedit.extension.search")
}
