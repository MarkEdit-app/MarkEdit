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
    wrapper.addSubview(loadingIndicator)
    wrapper.addSubview(statusView)

    layoutPanels()
    layoutWebView()
    layoutLoadingIndicator()
    layoutStatusView()

    // Trigger an additional layout loop to correct view (find panels) positions
    safeAreaObservation = view.observe(\.safeAreaInsets) { view, _ in
      view.needsLayout = true
    }

    // Press backspace or option to cancel the correction indicator,
    // it ensures a smoother word completion experience.
    NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
      if (event.keyCode == 51 || event.keyCode == 58), let self {
        NSSpellChecker.shared.declineCorrectionIndicator(for: self.webView)
      }

      return event
    }
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
      y: 8, // Vertical margins are intentionally larger to visually look the same
      width: statusView.frame.width,
      height: statusView.frame.height
    )

    view.mirrorImmediateSubviewIfNeeded(statusView)
  }

  func handleMouseMoved(_ event: NSEvent) {
    // WKWebView contentEditable keeps showing i-beam, fix that
    if NSCursor.current != NSCursor.arrow {
      let location = event.locationInWindow.y
      if location > view.frame.height - view.safeAreaInsets.top && location < view.frame.height {
        NSCursor.arrow.push()
      }
    }

    let trackingRect = {
      var bounds = view.bounds
      bounds.size.height -= view.safeAreaInsets.top
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
      } else {
        bridge.core.handleMouseEntered(clientX: clientX, clientY: clientY)
      }

      self.mouseExitedWindow = mouseExitedWindow
    }
  }

  func presentPopover(_ popover: NSPopover, rect: CGRect) {
    if focusTrackingView.superview == nil {
      webView.addSubview(focusTrackingView)
    }

    // The origin has to be inside the viewport, and the size cannot be zero
    focusTrackingView.frame = CGRect(
      x: max(0, rect.minX),
      y: max(0, rect.minY),
      width: max(1, rect.width),
      height: max(1, rect.height)
    )

    presentedPopover = popover
    popover.show(relativeTo: rect, of: focusTrackingView, preferredEdge: .maxX)
  }
}
