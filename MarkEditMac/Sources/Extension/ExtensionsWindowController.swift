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
  private weak var updateAllItem: NSMenuItem?

  func present(scrollTo category: ExtensionEntry.Category? = nil) {
    if category != nil {
      model.mode = .discover
    }

    showWindow(nil)
    window?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)

    if let category {
      extensionsVC?.scrollTo(category: category)
    }

    Task {
      // Fetch fresh every time the window opens; the conditional GET is cheap
      // and falls back to the cache when offline or unchanged.
      await model.load(forceRefresh: true)

      // Re-request in case the item only appeared after the fetch
      if let category {
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

// MARK: - NSMenuDelegate

extension ExtensionsWindowController: NSMenuDelegate {
  func menuNeedsUpdate(_ menu: NSMenu) {
    updateAllItem?.isEnabled = model.hasAvailableUpdates
  }
}

// MARK: - NSToolbarDelegate

extension ExtensionsWindowController: NSToolbarDelegate {
  func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    [.mode, .flexibleSpace, .actions]
  }

  func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    [.mode, .actions, .flexibleSpace, .space]
  }

  func toolbar(
    _ toolbar: NSToolbar,
    itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
    willBeInsertedIntoToolbar flag: Bool
  ) -> NSToolbarItem? {
    switch itemIdentifier {
    case .mode:
      return createModeItem()
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

// MARK: - Private

private extension ExtensionsWindowController {
  enum Constants {
    static let contributingURL = "https://github.com/MarkEdit-app/extensions#contributing"
  }

  var extensionsVC: ExtensionsViewController? {
    window?.contentViewController as? ExtensionsViewController
  }

  static func createController() -> ExtensionsWindowController {
    let window = NSWindow(
      contentRect: ExtensionsViewController.defaultContentRect,
      styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
      backing: .buffered,
      defer: false
    )

    window.title = Localized.Extension.windowTitle
    window.contentMinSize = CGSize(width: 640, height: 270)
    window.isReleasedWhenClosed = false

    let controller = Self(window: window)
    controller.model.primeFromCache()
    controller.configureToolbar()

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
      action: #selector(modeChanged(_:))
    )

    segmented.setSymbolImages([Icons.sparkles, Icons.shippingbox])
    segmented.selectedSegment = model.mode == .discover ? 0 : 1

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
      Task {
        await self?.model.updateAllExtensions()
      }
    }

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

  @objc func modeChanged(_ sender: NSSegmentedControl) {
    model.mode = sender.selectedSegment == 0 ? .discover : .installed
  }
}

// MARK: - Toolbar Identifiers

private extension NSToolbarItem.Identifier {
  static let mode = Self("app.markedit.extension.mode")
  static let actions = Self("app.markedit.extension.actions")
}
