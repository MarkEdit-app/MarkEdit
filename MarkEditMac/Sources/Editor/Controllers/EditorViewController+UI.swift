//
//  EditorViewController+UI.swift
//  MarkEditMac
//
//  Created by cyan on 12/27/22.
//

import AppKit
import WebKit
import MarkEditKit
import Statistics

extension EditorViewController {
  func setUp() {
    let wrapper = NSView(frame: CGRect(x: 0, y: 0, width: 720, height: 480))
    self.view = wrapper

    wrapper.addSubview(replacePanel) // ReplacePanel must go before FindPanel
    wrapper.addSubview(findPanel)
    wrapper.addSubview(panelDivider)
    wrapper.addSubview(webView)
    wrapper.addSubview(statusView)

    if !hasFinishedLoading {
      wrapper.addSubview(loadingIndicator)
    }

    layoutPanels()
    layoutWebView()
    layoutLoadingIndicator()
    layoutStatusView()

    // Initially hide panels to prevent being found by VoiceOver
    findPanel.isHidden = true
    replacePanel.isHidden = true

    // Trigger an additional layout loop to correct view (find panels) positions
    safeAreaObservation = view.observe(\.safeAreaInsets) { view, _ in
      Task { @MainActor in
        view.needsLayout = true
      }
    }

    // Track popovers that use editor as the positioning container
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(popoverDidShow(_:)),
      name: NSPopover.didShowNotification,
      object: nil
    )

    addLocalMonitorForEvents()
  }

  func configureToolbar() {
    let toolbar = NSToolbar(identifier: "EditorToolbar")
    toolbar.displayMode = .iconOnly
    toolbar.delegate = self
    toolbar.allowsUserCustomization = true
    toolbar.autosavesConfiguration = true

    view.window?.toolbar = toolbar
    view.window?.toolbar?.validateVisibleItems()

    view.window?.acceptsMouseMovedEvents = true
    view.window?.appearance = AppTheme.current.resolvedAppearance

    updateWindowColors(.current)
  }

  func updateWindowColors(_ theme: AppTheme) {
    let backgroundColor = webBackgroundColor ?? theme.windowBackground
    view.window?.backgroundColor = backgroundColor
    view.window?.toolbarContainerView?.layerBackgroundColor = backgroundColor

    let prefersTintedToolbar = theme.prefersTintedToolbar
    (view.window as? EditorWindow)?.prefersTintedToolbar = prefersTintedToolbar

    statusView.setBackgroundColor(backgroundColor)
    findPanel.setBackgroundColor(backgroundColor)
    replacePanel.setBackgroundColor(backgroundColor)
  }

  @available(macOS 15.1, *)
  func updateWritingTools(isActive: Bool) {
    let performUpdate = {
      // Ignore beforeInput handling to work around undo stack issues
      self.bridge.writingTools.setActive(isActive: isActive)

      // Invisible rendering doesn't work well with WritingTools, temporarily disable it for now
      self.setInvisiblesBehavior(behavior: isActive ? .never : AppPreferences.Editor.invisiblesBehavior)
    }

    if isActive {
      performUpdate()
    } else {
      DispatchQueue.main.asyncAfter(
        deadline: .now() + 0.2,
        execute: performUpdate
      )
    }
  }

  func layoutPanels(animated: Bool = false) {
    findPanel.update(animated).frame = CGRect(
      x: 0,
      y: contentHeight - (findPanel.mode == .hidden ? 0 : findPanel.frame.height),
      width: view.bounds.width,
      height: findPanel.frame.height
    )

    replacePanel.update(animated).frame = CGRect(
      x: findPanel.frame.minX,
      y: findPanel.frame.minY - (findPanel.mode == .replace ? replacePanel.frame.height : 0),
      width: findPanel.frame.width,
      height: findPanel.frame.height - findPanel.searchField.frame.minY
    )

    replacePanel.layoutInfo = (findPanel.searchField.frame, findPanel.findButtons.frame.height)
    panelDivider.update(animated).frame = CGRect(x: 0, y: (findPanel.mode == .replace ? replacePanel : findPanel).frame.minY, width: view.frame.width, height: panelDivider.length)
  }

  func layoutWebView(animated: Bool = false) {
    // Move the view instead of changing its height,
    // because resizing would introduce unnecessary updates,
    // which results in sluggish animation.
    let height = contentHeight
    let offset = panelDivider.frame.minY - height

    webView.update(animated).frame = CGRect(
      x: 0,
      y: offset,
      width: view.bounds.width,
      height: height
    )
  }

  func layoutLoadingIndicator() {
    guard !loadingIndicator.hasUnfinishedAnimations else {
      return
    }

    let size: Double = 72
    loadingIndicator.frame = CGRect(
      x: (view.bounds.width - size) * 0.5,
      y: (view.bounds.height - size) * 0.5,
      width: size,
      height: size
    )

    // Hide the indicator when the window is small enough
    loadingIndicator.isHidden = view.bounds.width < 200 || view.bounds.height < 200
  }

  func layoutStatusView() {
    statusView.frame = CGRect(
      x: view.bounds.width - statusView.frame.width - 6,
      y: bottomPanelHeight + 8, // Vertical margins are intentionally larger to visually look the same
      width: statusView.frame.width,
      height: statusView.frame.height
    )

    view.mirrorImmediateSubviewIfNeeded(statusView)
  }

  func handleMouseMoved(_ event: NSEvent) {
    guard view.window?.isKeyWindow == true else {
      return
    }

    // WKWebView contentEditable keeps showing i-beam, fix that
    if NSCursor.current != NSCursor.arrow {
      let location = event.locationInWindow.y
      if location > contentHeight && location < view.frame.height {
        NSCursor.arrow.push()
      }
    }

    let trackingRect = {
      var bounds = view.bounds
      bounds.size.height = contentHeight - findPanelHeight
      return bounds
    }()

    // WebKit doesn't update hover state reliably, e.g., "mouseup" outside the window,
    // propagate a native event to help update the UI.
    let mouseExitedWindow = !trackingRect.contains(event.locationInWindow)
    if mouseExitedWindow != self.mouseExitedWindow && AppPreferences.Editor.showLineNumbers {
      let clientX = event.locationInWindow.x
      let clientY = event.locationInWindow.y

      if mouseExitedWindow {
        bridge.core.handleMouseExited(clientX: clientX, clientY: clientY)
      }

      self.mouseExitedWindow = mouseExitedWindow
    }
  }

  func startTextEditing() {
    view.window?.makeFirstResponder(webView)
  }

  func refreshEditFocus() {
    startTextEditing()
    bridge.selection.refreshEditFocus()
  }

  func resignFindPanelFocus() {
    guard isFindPanelFirstResponder else {
      return
    }

    startTextEditing()
  }

  func removeFloatingUIElements() {
    if completionContext.isPanelVisible {
      cancelCompletion()
    }

    NSSpellChecker.shared.declineCorrectionIndicator(for: webView)
    presentedPopover?.close()
  }

  @discardableResult
  func removePresentedPopovers(contentClass: AnyClass) -> Bool {
    guard let presented = presentedViewControllers?.filter({ $0.isKind(of: contentClass) }) else {
      return false
    }

    guard !presented.isEmpty else {
      return false
    }

    presented.forEach { dismiss($0) }
    return true
  }

  func resetUserDefinedMenus() {
    guard let mainMenu = NSApp.mainMenu else {
      return Logger.assertFail("Missing mainMenu")
    }

    // Remove existing ones, always recreate the menu
    (mainMenu.items.filter {
      $0.submenu?.identifier?.rawValue.hasPrefix(EditorMainMenu.uniquePrefix) == true
    }).forEach {
      mainMenu.removeItem($0)
    }

    for spec in userDefinedMenus {
      let menu = createMenu(items: spec.items, handler: bridge.ui.handleMainMenuAction)
      menu.identifier = NSUserInterfaceItemIdentifier("\(EditorMainMenu.uniquePrefix)#\(spec.menuID)")
      menu.delegate = NSApp.appDelegate

      let item = NSMenuItem(title: spec.title)
      item.submenu = menu

      // Preferably, make it the last one before the "Help" menu
      if let index = (mainMenu.items.firstIndex { $0.submenu == NSApp.helpMenu }) {
        mainMenu.insertItem(item, at: index)
      } else {
        mainMenu.addItem(item)
      }
    }
  }

  // MARK: - Exposed to user scripts

  func addMainMenu(menuID: String, title: String, items: [WebMenuItem]) {
    userDefinedMenus.removeAll {
      $0.menuID == menuID
    }

    userDefinedMenus.append(EditorMainMenu(
      menuID: menuID,
      title: title,
      items: items
    ))

    resetUserDefinedMenus()
  }

  func showContextMenu(items: [WebMenuItem], location: CGPoint) {
    let menu = createMenu(items: items, handler: bridge.ui.handleContextMenuAction)
    menu.identifier = EditorWebView.userDefinedMenuID

    NSCursor.arrow.push()
    menu.popUp(positioning: nil, at: location, in: webView)
  }

  func showAlert(title: String?, message: String?, buttons: [String]?) -> NSApplication.ModalResponse {
    let alert = NSAlert()
    alert.messageText = title ?? ""
    alert.informativeText = message ?? ""

    buttons?.forEach {
      alert.addButton(withTitle: $0)
    }

    return alert.runModal()
  }

  func showTextBox(title: String?, placeholder: String?, defaultValue: String?) -> String? {
    let alert = NSAlert()
    alert.messageText = title ?? ""
    alert.addButton(withTitle: Localized.General.okay)
    alert.addButton(withTitle: Localized.General.cancel)

    let textField = NSTextField(frame: CGRect(x: 0, y: 0, width: 256, height: 22))
    textField.placeholderString = placeholder
    textField.stringValue = defaultValue ?? ""
    alert.accessoryView = textField

    return alert.runModal() == .alertFirstButtonReturn ? textField.stringValue : nil
  }
}

// MARK: - Private

private extension EditorViewController {
  var contentHeight: Double {
    view.bounds.height - view.safeAreaInsets.top
  }

  var findPanelHeight: Double {
    findPanel.isHidden ? 0 : findPanel.frame.height
  }

  @objc func popoverDidShow(_ notification: Notification) {
    guard let popover = notification.object as? NSPopover else {
      return
    }

    guard popover.sourceView?.belongs(to: view) == true else {
      return
    }

    presentedPopover = popover
  }

  func createMenu(
    items: [WebMenuItem],
    handler: @escaping (String, ((Result<Void, WKWebView.InvokeError>) -> Void)?) -> Void
  ) -> NSMenu {
    let menu = NSMenu()

    for spec in items {
      if spec.separator {
        menu.addItem(.separator())
      } else if let children = spec.children {
        let item = NSMenuItem(title: spec.title ?? "")
        item.submenu = createMenu(items: children, handler: handler)
        menu.addItem(item)
      } else if let title = spec.title {
        let item = menu.addItem(withTitle: title) { handler(spec.id, nil) }
        item.keyEquivalent = spec.key ?? ""
        item.keyEquivalentModifierMask = .init(stringValues: spec.modifiers ?? [])
      } else {
        Logger.assertFail("Invalid spec of menu item: \(spec)")
      }
    }

    return menu
  }
}
