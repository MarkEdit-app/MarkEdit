//
//  SettingsTabViewController.swift
//
//  Created by cyan on 1/28/23.
//

import AppKit
import SwiftUI

/**
 Wrapper view controller for a settings tab in SettingsRootViewController.
 */
public final class SettingsTabViewController: NSViewController {
  let tabViewItem: NSTabViewItem
  let contentView: NSView

  public init(_ rootView: some View, title: String, icon: String) {
    tabViewItem = NSTabViewItem()
    tabViewItem.label = title
    tabViewItem.image = NSImage(systemSymbolName: icon, accessibilityDescription: title)
    contentView = NSHostingView(rootView: rootView)
    super.init(nibName: nil, bundle: nil)

    self.title = title
    self.tabViewItem.viewController = self
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func loadView() {
    view = NSView(frame: .zero)
    view.addSubview(contentView)

    // Rely on SwiftUI view size to have auto-sizing,
    // the window height respects to the contentView height.
    contentView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      contentView.topAnchor.constraint(equalTo: view.topAnchor),
    ])
  }
}
