//
//  EditorViewController+UI.swift
//  MarkEditMac
//
//  Created by cyan on 12/27/22.
//

import AppKit
import AppKitControls
import WebKit
import MarkEditKit
import Statistics

extension EditorViewController {
  var contentRectOffset: Double {
    // E.g., when the find panel shows
    contentHeight - webView.frame.height
  }

  func setUp() {
    let wrapper = NSView(frame: CGRect(x: 0, y: 0, width: 720, height: 480))
    self.view = wrapper

    if AppDesign.modernTitleBar {
      wrapper.addSubview(modernBackgroundView)
    }

    wrapper.addSubview(findPanel)
    wrapper.addSubview(replacePanel)
    wrapper.addSubview(panelDivider)

    // findPanel is added before replacePanel to ensure the key view loop,
    // but we want findPanel visually above the replacePanel to play UI tricks.
    if let findPanelLayer = findPanel.layer {
      wrapper.layer?.insertSublayer(findPanelLayer, above: replacePanel.layer)
    }

    wrapper.addSubview(webView)
    wrapper.addSubview(statusView)

    if AppDesign.modernTitleBar {
      wrapper.addSubview(modernEffectView)
      wrapper.addSubview(modernTintedView)
      wrapper.addSubview(modernDividerView)
    }

    if !hasFinishedLoading {
      wrapper.addSubview(loadingIndicator)
    }

    layoutPanels()
    layoutWebView()
    layoutLoadingIndicator()
    layoutStatusView()

    if AppDesign.modernTitleBar {
      modernBackgroundView.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        modernBackgroundView.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
        modernBackgroundView.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
        modernBackgroundView.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
        modernBackgroundView.topAnchor.constraint(equalTo: modernEffectView.bottomAnchor),
      ])

      if let effectView = modernEffectView as? NSVisualEffectView {
        effectView.material = .titlebar
      } else if #available(macOS 26.0, *) {
        (modernEffectView as? NSGlassEffectView)?.cornerRadius = 0
      }

      modernEffectView.clipsToBounds = true // To cut the shadows
      modernEffectView.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        modernEffectView.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
        modernEffectView.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
        modernEffectView.topAnchor.constraint(equalTo: wrapper.topAnchor),
        modernEffectHeight,
      ])

      // It covers precisely to provide a tinted color
      modernTintedView.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        modernTintedView.leadingAnchor.constraint(equalTo: modernEffectView.leadingAnchor),
        modernTintedView.trailingAnchor.constraint(equalTo: modernEffectView.trailingAnchor),
        modernTintedView.topAnchor.constraint(equalTo: modernEffectView.topAnchor),
        modernTintedView.bottomAnchor.constraint(equalTo: modernEffectView.bottomAnchor),
      ])

      // To avoid duplicate dividers
      if AppDesign.modernStyle {
        modernDividerView.alphaValue = 0
        modernDividerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
          modernDividerView.leadingAnchor.constraint(equalTo: findPanel.leadingAnchor),
          modernDividerView.trailingAnchor.constraint(equalTo: findPanel.trailingAnchor),
          modernDividerView.topAnchor.constraint(equalTo: findPanel.topAnchor),
          modernDividerView.heightAnchor.constraint(equalToConstant: modernDividerView.length),
        ])
      }
    }

    // Initially hide panels to prevent being found by VoiceOver
    findPanel.isHidden = true
    replacePanel.isHidden = true

    // Trigger an additional layout loop to correct view (find panels) positions
    safeAreaObservation = view.observe(\.safeAreaInsets) { view, _ in
      Task { @MainActor in
        view.needsLayout = true
      }
    }

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(windowDidBecomeMain(_:)),
      name: NSWindow.didBecomeMainNotification,
      object: nil
    )

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(windowDidResignMain(_:)),
      name: NSWindow.didResignMainNotification,
      object: nil
    )

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
    resetCustomToolbarItems()
  }

  func updateWindowColors(_ theme: AppTheme) {
    let backgroundColor = webBackgroundColor ?? theme.windowBackground
    view.window?.backgroundColor = backgroundColor
    view.window?.toolbarContainerView?.layerBackgroundColor = backgroundColor

    let prefersTintedToolbar = theme.prefersTintedToolbar || backgroundColor.isTintedColor
    (view.window as? EditorWindow)?.prefersTintedToolbar = prefersTintedToolbar

    if AppDesign.modernTitleBar {
      let isMainWindow = view.window?.isMainWindow ?? false
      let reduceTransparency = !isMainWindow || AppDesign.reduceTransparency
      let baseColor = backgroundColor.withAlphaComponent(reduceTransparency ? 1.0 : 0.01)

      view.window?.backgroundColor = baseColor
      view.window?.toolbarContainerView?.layerBackgroundColor = baseColor

      modernBackgroundView.layerBackgroundColor = backgroundColor
      modernEffectView.isHidden = reduceTransparency
      modernTintedView.layerBackgroundColor = baseColor

      let alphaValue = {
        if modernEffectView is NSVisualEffectView {
          return prefersTintedToolbar ? 0.7 : 0.3
        }

        // Glass view needs less transparent color to be tinted
        return prefersTintedToolbar ? 0.8 : 0.5
      }()

      let tintColor = backgroundColor.withAlphaComponent(alphaValue).resolvedColor()

      // For NSGlassEffectView, the built-in tintColor is preferred
      if #available(macOS 26.0, *), let glassView = modernEffectView as? NSGlassEffectView {
        glassView.tintColor = tintColor
        glassView.layerBackgroundColor = backgroundColor.withAlphaComponent(0.66)
      } else {
        modernTintedView.layerBackgroundColor = tintColor
      }

      // Hide the effect view and remove the opacity of the title bar view
      if reduceTransparency {
        modernTintedView.layerBackgroundColor = backgroundColor
      }
    }

    statusView.setBackgroundColor(backgroundColor)
    findPanel.setBackgroundColor(backgroundColor)
    replacePanel.setBackgroundColor(backgroundColor)
  }

  @available(macOS 15.1, *)
  func updateWritingTools(isActive: Bool) {
    let performUpdate = {
      // Work around undo stack and selection range issues
      self.bridge.writingTools.setActive(
        isActive: isActive,
        reselect: MarkEditWritingTools.shouldReselect(with: MarkEditWritingTools.requestedTool)
      )

      // Invisible rendering doesn't work well with Writing Tools, temporarily disable it for now
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
    findPanel.update(animated).frame = findPanelRect
    replacePanel.update(animated).frame = replacePanelRect
    panelDivider.update(animated).frame = panelDividerRect

    replacePanel.layoutInfo = (
      findPanel.searchField.frame,
      findPanel.findButtons.frame.height
    )

    if AppDesign.modernTitleBar {
      modernEffectHeight.constant = view.safeAreaInsets.top
      modernDividerView.update(animated).alphaValue = findPanel.mode == .hidden ? 0 : 1
    }
  }

  func layoutWebView(animated: Bool = false) {
    // Move the view instead of changing its height,
    // because resizing would introduce unnecessary updates,
    // which results in sluggish animation.
    let height = contentHeight
    let offset = panelDividerRect.minY - height

    webView.update(animated).frame = CGRect(
      x: 0,
      y: offset + findPanelHeight,
      width: view.bounds.width,
      height: height - findPanelHeight
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
    let margin: Double = {
      if AppDesign.modernStyle {
        // To fit better for the huge corner radius
        return 16
      }

      return 6
    }()

    statusView.frame = CGRect(
      x: view.bounds.width - statusView.frame.width - margin,
      y: bottomPanelHeight + margin + 2, // Vertical margins are intentionally larger to visually look the same
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

  func updateUserDefinedMenus(_ menu: NSMenu) {
    let items = menu.items.compactMap {
      $0 as? UserDefinedMenuItem
    }

    items.forEach { item in
      guard let stateGetterID = item.stateGetterID else {
        return
      }

      Task {
        if let state = try? await bridge.api.getMenuItemState(id: stateGetterID) {
          item.isEnabled = view.window != nil && (state.isEnabled ?? true)
          item.setOn(state.isSelected ?? false)
        }
      }
    }
  }

  func resetUserDefinedMenuItems() {
    guard view.window?.isKeyWindow == true else {
      return Logger.log(.debug, "Menu items are for the key window")
    }

    guard let menu = NSApp.appDelegate?.mainExtensionsMenu else {
      return Logger.assertFail("Missing main extensions menu")
    }

    // Remove existing ones, always recreate a new item
    (menu.items.filter {
      $0.identifier?.rawValue.hasPrefix(EditorMenuItem.uniquePrefix) == true
    }).forEach {
      menu.removeItem($0)
    }

    for spec in userDefinedMenuItems {
      let item = createMenuItem(spec: spec.item, handler: bridge.api.handleMainMenuAction)
      item.identifier = NSUserInterfaceItemIdentifier("\(EditorMenuItem.uniquePrefix).\(spec.id)")

      // Preferably, make it the last one before the special divider
      if let index = (menu.items.firstIndex { $0.identifier?.rawValue == EditorMenuItem.specialDivider }) {
        menu.insertItem(item, at: index)
      } else {
        menu.addItem(item)
      }
    }

    resetCustomToolbarItems()
  }

  func resetCustomToolbarItems() {
    let toolbarItems = view.window?.toolbar?.items.compactMap {
      $0 as? NSMenuToolbarItem
    }

    let specsDict: [String: WebMenuItem] = Dictionary(
      uniqueKeysWithValues: userDefinedMenuItems.compactMap {
        guard let title = $0.item.title else {
          return nil
        }

        return (title, $0.item)
      }
    )

    toolbarItems?.forEach { toolbarItem in
      guard let title = customItem(with: toolbarItem.itemIdentifier)?.menuName else {
        return
      }

      if let spec = specsDict[title] {
        let menuItem = createMenuItem(
          spec: spec,
          handler: bridge.api.handleMainMenuAction
        )

        menuItem.setEnabledRecursively(isEnabled: true)
        toolbarItem.menu = menuItem.submenu ?? NSMenu()
      } else if let submenu = NSApp.mainMenu?.firstMenuNamed(title)?.submenu?.copiedMenu {
        toolbarItem.menu = submenu
      } else {
        Logger.log(.error, "Missing menu named: \(title)")
      }

      updateUserDefinedMenus(toolbarItem.menu)
    }
  }

  // MARK: - Exposed to user scripts

  func addMainMenuItems(items: [(id: String, item: WebMenuItem)]) {
    userDefinedMenuItems.removeAll { old in
      items.contains { new in old.id == new.id }
    }

    userDefinedMenuItems.append(contentsOf: items.map {
      EditorMenuItem(id: $0.id, item: $0.item)
    })

    resetUserDefinedMenuItems()
  }

  func showContextMenu(items: [WebMenuItem], location: CGPoint) {
    let menu = createMenu(items: items, handler: bridge.api.handleContextMenuAction)
    menu.identifier = EditorWebView.userDefinedContextMenuID

    NSCursor.arrow.push()
    menu.popUp(positioning: nil, at: location, in: webView)
  }

  func showAlert(title: String?, message: String?, buttons: [String]?) async -> NSApplication.ModalResponse {
    let alert = NSAlert()
    alert.messageText = title ?? ""
    alert.informativeText = message ?? ""

    buttons?.forEach {
      alert.addButton(withTitle: $0)
    }

    return await presentSheetModal(alert)
  }

  func showTextBox(title: String?, placeholder: String?, defaultValue: String?) async -> String? {
    class TextField: NSTextField {
      override func performKeyEquivalent(with event: NSEvent) -> Bool {
        // The default "selectAll" is not available here
        if event.deviceIndependentFlags == .command, event.keyCode == .kVK_ANSI_A {
          currentEditor()?.selectAll(nil)
          return true
        }

        return super.performKeyEquivalent(with: event)
      }
    }

    let alert = NSAlert()
    alert.messageText = title ?? ""
    alert.addButton(withTitle: Localized.General.done)
    alert.addButton(withTitle: Localized.General.cancel)

    let textField = TextField(frame: CGRect(x: 0, y: 0, width: 256, height: 22))
    textField.placeholderString = placeholder
    textField.stringValue = defaultValue ?? ""
    alert.accessoryView = textField

    textBoxInputObserver = NotificationCenter.default.addObserver(
      forName: NSWindow.didBecomeKeyNotification,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      Task { @MainActor in
        if let window = notification.object as? NSWindow, window == textField.window {
          window.makeFirstResponder(textField)
          if let observer = self?.textBoxInputObserver {
            self?.textBoxInputObserver = nil
            NotificationCenter.default.removeObserver(observer)
          }
        }
      }
    }

    let response = await presentSheetModal(alert)
    return response == .alertFirstButtonReturn ? textField.stringValue : nil
  }

  func showSavePanel(data: Data, fileName: String?) async -> Bool {
    let savePanel = NSSavePanel()
    savePanel.nameFieldStringValue = fileName ?? ""
    savePanel.isExtensionHidden = false
    savePanel.titlebarAppearsTransparent = true

    guard await presentSheetModal(savePanel) == .OK, let url = savePanel.url else {
      // Cancelled
      return false
    }

    do {
      try data.write(to: url, options: .atomic)
      return true
    } catch {
      Logger.log(.error, "Failed to save the file")
      return false
    }
  }
}

// MARK: - Private

private extension EditorViewController {
  final class UserDefinedMenuItem: NSMenuItem {
    var stateGetterID: String?
  }

  var contentHeight: Double {
    view.bounds.height - view.safeAreaInsets.top
  }

  var findPanelHeight: Double {
    switch findPanel.mode {
    case .hidden: return 0
    case .find: return findPanel.frame.height
    case .replace: return findPanel.frame.height + replacePanel.frame.height
    }
  }

  var findPanelRect: CGRect {
    CGRect(
      x: 0,
      y: contentHeight - (findPanel.mode == .hidden ? 0 : findPanel.frame.height),
      width: view.bounds.width,
      height: findPanel.frame.height
    )
  }

  var replacePanelRect: CGRect {
    CGRect(
      x: findPanelRect.minX,
      y: findPanelRect.minY - (findPanel.mode == .replace ? replacePanel.frame.height : 0),
      width: findPanel.frame.width,
      height: findPanel.frame.height - findPanel.searchField.frame.minY
    )
  }

  var panelDividerRect: CGRect {
    let offset: Double = {
      if AppDesign.modernStyle && findPanel.mode == .hidden {
        return contentHeight - panelDivider.length
      }

      return (findPanel.mode == .replace ? replacePanelRect : findPanelRect).minY
    }()

    return CGRect(
      x: 0,
      y: offset,
      width: view.frame.width,
      height: panelDivider.length
    )
  }

  @objc func windowDidBecomeMain(_ notification: Notification) {
    guard (notification.object as? NSWindow) == view.window else {
      return
    }

    if AppDesign.modernStyle {
      updateWindowColors(.current)
    }

    if AppRuntimeConfig.nativeSearchQuerySync {
      updateNativeSearchQuery()
    }
  }

  @objc func windowDidResignMain(_ notification: Notification) {
    guard (notification.object as? NSWindow) == view.window else {
      return
    }

    if AppDesign.modernStyle {
      updateWindowColors(.current)
    }
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

  func createMenuItem(
    spec: WebMenuItem,
    handler: @escaping (String, ((Result<Void, WKWebView.InvokeError>) -> Void)?) -> Void
  ) -> NSMenuItem {
    if spec.separator {
      return .separator()
    } else if let children = spec.children {
      let item = UserDefinedMenuItem(title: spec.title ?? "")
      item.image = createMenuIcon(spec: spec)
      item.submenu = createMenu(items: children, handler: handler)
      return item
    } else if let title = spec.title {
      let item = UserDefinedMenuItem(title: title)
      if let actionID = spec.actionID {
        item.addAction { handler(actionID, nil) }
      }

      item.stateGetterID = spec.stateGetterID
      item.image = createMenuIcon(spec: spec)
      item.keyEquivalent = spec.key ?? ""
      item.keyEquivalentModifierMask = .init(stringValues: spec.modifiers ?? [])
      return item
    } else {
      Logger.assertFail("Invalid spec of menu item: \(spec)")
      return UserDefinedMenuItem()
    }
  }

  func createMenu(
    items: [WebMenuItem],
    handler: @escaping (String, ((Result<Void, WKWebView.InvokeError>) -> Void)?) -> Void
  ) -> NSMenu {
    let menu = NSMenu()
    items.map { createMenuItem(spec: $0, handler: handler) }.forEach {
      menu.addItem($0)
    }

    menu.delegate = self
    return menu
  }

  func createMenuIcon(spec: WebMenuItem) -> NSImage? {
    guard let icon = spec.icon else {
      return nil
    }

    if let image = NSImage(systemSymbolName: icon, accessibilityDescription: nil) {
      return image
    }

    if let data = Data(base64Encoded: icon, options: .ignoreUnknownCharacters) {
      return NSImage(data: data)
    }

    return nil
  }
}
