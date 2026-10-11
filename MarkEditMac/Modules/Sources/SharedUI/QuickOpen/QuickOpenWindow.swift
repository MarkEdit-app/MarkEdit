//
//  QuickOpenWindow.swift
//
//  Created by cyan on 1/17/23.
//

import AppKit

public final class QuickOpenWindow: NSWindow {
  private enum Constants {
    // Values are copied from Xcode
    static let width: Double = 456
    static let height: Double = 48
  }

  /// The handler returns `true` to dismiss the window, or `false` to beep and select the input for correction.
  public init(
    effectViewType: NSView.Type,
    tintColor: NSColor? = nil,
    relativeTo parentRect: CGRect,
    placeholder: String,
    accessibilityHelp: String,
    iconName: String,
    defaultText: String? = nil,
    handler: @escaping (String) -> Bool
  ) {
    let rect = CGRect(
      x: parentRect.minX + (parentRect.width - Constants.width) * 0.5,
      y: parentRect.minY + parentRect.height - Constants.height - 150,
      width: Constants.width,
      height: Constants.height
    )

    super.init(
      contentRect: rect,
      styleMask: .borderless,
      backing: .buffered,
      defer: false
    )

    self.contentView = QuickOpenView(
      effectViewType: effectViewType,
      tintColor: tintColor,
      frame: rect,
      placeholder: placeholder,
      accessibilityHelp: accessibilityHelp,
      iconName: iconName,
      defaultText: defaultText,
      handler: handler
    )

    self.isMovableByWindowBackground = true
    self.isOpaque = false
    self.hasShadow = true
    self.backgroundColor = .clear
  }

  public var tintColor: NSColor? {
    get {
      (contentView as? QuickOpenView)?.tintColor
    }
    set {
      (contentView as? QuickOpenView)?.tintColor = newValue
    }
  }

  override public var canBecomeKey: Bool {
    true
  }

  override public func resignKey() {
    orderOut(self)
  }

  override public func cancelOperation(_ sender: Any?) {
    orderOut(self)
  }
}
