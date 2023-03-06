//
//  EditorViewController+UI.swift
//  MarkEditMac
//
//  Created by cyan on 12/27/22.
//

import AppKit

extension EditorViewController {
  func setUp() {
    let wrapper = NSView(frame: CGRect(x: 0, y: 0, width: 720, height: 480))
    self.view = wrapper

    wrapper.addSubview(replacePanel) // ReplacePanel must go before FindPanel
    wrapper.addSubview(findPanel)
    wrapper.addSubview(panelDivider)
    wrapper.addSubview(webView)
    wrapper.addSubview(statusView)

    layoutPanels()
    layoutWebView()
    layoutStatusView()

    // Trigger an additional layout loop to correct view (find panels) positions
    safeAreaObservation = view.observe(\.safeAreaInsets) { view, _ in
      view.needsLayout = true
    }

    // Press backspace or option to cancel the correction indicator,
    // it ensures a smoother text completion experience.
    NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
      if (event.keyCode == 51 || event.keyCode == 58), let self {
        NSSpellChecker.shared.declineCorrectionIndicator(for: self.webView)
      }

      return event
    }
  }

  func setWindowHidden(_ isHidden: Bool) {
    // There's also "setIsVisible" but it will also be called in AppKit internally
    view.window?.alphaValue = isHidden ? 0 : 1
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

    updateWindowColors(AppTheme.current)
  }

  func updateWindowColors(_ theme: AppTheme) {
    let backgroundColor = theme.windowBackground
    view.window?.backgroundColor = backgroundColor
    view.window?.toolbarContainerView?.layerBackgroundColor = backgroundColor

    statusView.setBackgroundColor(backgroundColor)
    findPanel.setBackgroundColor(backgroundColor)
    replacePanel.setBackgroundColor(backgroundColor)
  }

  func layoutPanels(animated: Bool = false) {
    findPanel.update(animated).frame = CGRect(
      x: 0,
      y: view.bounds.height - view.safeAreaInsets.top - (findPanel.mode == .hidden ? 0 : findPanel.frame.height),
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
    webView.update(animated).frame = CGRect(
      x: 0,
      y: 0,
      width: view.bounds.width,
      height: panelDivider.frame.minY
    )
  }

  func layoutStatusView() {
    statusView.frame = CGRect(
      x: view.bounds.width - statusView.frame.width - 6,
      y: 8, // Vertical margins are intentionally larger to visually look the same
      width: statusView.frame.width,
      height: statusView.frame.height
    )

    view.mirrorImmediateSubviewIfNeeded(statusView)
  }

  func handleMouseMoved(_ event: NSEvent) {
    guard NSCursor.current != NSCursor.arrow else {
      return
    }

    // WKWebView contentEditable keeps showing i-beam, fix that
    let location = event.locationInWindow.y
    if location > view.frame.height - view.safeAreaInsets.top && location < view.frame.height {
      NSCursor.arrow.push()
    }
  }

  func presentPopover(_ popover: NSPopover, rect: CGRect) {
    if focusTrackingView.superview == nil {
      webView.addSubview(focusTrackingView)
    }

    focusTrackingView.frame = CGRect(
      x: rect.minX,
      y: rect.minY,
      width: max(1, rect.width), // It can be zero, which is invalid
      height: rect.height
    )

    popover.show(relativeTo: rect, of: focusTrackingView, preferredEdge: .maxX)
  }
}
