//
//  SettingsRootViewController.swift
//
//  Created by cyan on 1/26/23.
//

import AppKit
import AppKitExtensions

/**
 Root container for settings view, multi-tab based.
 */
public final class SettingsRootViewController: NSTabViewController {
  private var tabs: [SettingsTabViewController]?
  private var animateChanges = false

  public static func withTabs(_ tabs: [SettingsTabViewController]) -> NSWindowController {
    let contentVC = Self()
    contentVC.tabs = tabs

    let window = NSPanel(contentViewController: contentVC)
    window.styleMask = [.titled, .closable]

    return NSWindowController(window: window)
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    tabStyle = .toolbar

    tabs?.forEach {
      addTabViewItem($0.tabViewItem)
    }
  }

  override public func viewDidAppear() {
    super.viewDidAppear()
    view.window?.moveToCenter()
  }
}

// MARK: - NSTabViewDelegate

extension SettingsRootViewController {
  override public func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
    super.tabView(tabView, didSelect: tabViewItem)
    guard let contentVC = tabViewItem?.viewController as? SettingsTabViewController else {
      return
    }

    // Performing in the next run loop has a better visual effect
    DispatchQueue.afterDelay(seconds: 0.02) {
      self.view.window?.setFrameSize(CGSize(
        width: 580,
        height: contentVC.contentView.frame.size.height
      ), animated: self.animateChanges)

      // Enable animations after initial selection
      self.animateChanges = true
    }

    // Mimic the effect of some 1st-party apps, such as Calendar.app,
    // don't use isHidden, it affects the layout.
    view.alphaValue = 0
    DispatchQueue.afterDelay(seconds: 0.2) {
      self.view.alphaValue = 1
    }
  }
}

// MARK: - Private

private extension DispatchQueue {
  static func afterDelay(seconds: TimeInterval, execute: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: execute)
  }
}
