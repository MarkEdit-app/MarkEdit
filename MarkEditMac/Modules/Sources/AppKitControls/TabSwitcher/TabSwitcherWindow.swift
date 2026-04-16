//
//  TabSwitcherWindow.swift
//
//  Created by lamchau on 4/16/26.
//

import AppKit

public struct TabSwitcherItem {
  public let title: String
  public let subtitle: String
  public let handler: @MainActor () -> Void

  public init(title: String, subtitle: String, handler: @escaping @MainActor () -> Void) {
    self.title = title
    self.subtitle = subtitle
    self.handler = handler
  }
}

public final class TabSwitcherWindow: NSWindow {
  private enum Constants {
    static let width: Double = 500
    static let height: Double = 320
    static let topOffset: Double = 100
  }

  public init(
    effectViewType: NSView.Type,
    relativeTo parentRect: CGRect,
    placeholder: String,
    accessibilityHelp: String,
    emptyMessage: String,
    items: [TabSwitcherItem],
    initialSelection: Int = 0
  ) {
    let rect = CGRect(
      x: parentRect.minX + (parentRect.width - Constants.width) * 0.5,
      y: parentRect.minY + parentRect.height - Constants.height - Constants.topOffset,
      width: Constants.width,
      height: Constants.height
    )

    let view = TabSwitcherView(
      effectViewType: effectViewType,
      frame: rect,
      placeholder: placeholder,
      accessibilityHelp: accessibilityHelp,
      emptyMessage: emptyMessage,
      items: items,
      initialSelection: initialSelection
    )

    super.init(
      contentRect: rect,
      styleMask: .borderless,
      backing: .buffered,
      defer: false
    )

    self.contentView = view
    self.isMovableByWindowBackground = true
    self.isOpaque = false
    self.hasShadow = true
    self.backgroundColor = .clear
  }

  override public var canBecomeKey: Bool {
    true
  }

  override public func resignKey() {
    super.resignKey()
    orderOut(self)
  }

  override public func cancelOperation(_ sender: Any?) {
    orderOut(self)
  }
}
