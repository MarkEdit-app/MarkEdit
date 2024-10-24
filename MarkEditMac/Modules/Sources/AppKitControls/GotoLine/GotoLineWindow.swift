//
//  GotoLineWindow.swift
//
//  Created by cyan on 1/17/23.
//

import AppKit

public final class GotoLineWindow: NSWindow {
  private enum Constants {
    // Values are copied from Xcode
    static let width: Double = 456
    static let height: Double = 48
  }

  public init(
    relativeTo parentRect: CGRect,
    placeholder: String,
    accessibilityHelp: String,
    iconName: String,
    defaultLineNumber: Int? = nil,
    handler: @escaping (Int) -> Void
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

    self.contentView = GotoLineView(
      frame: rect,
      placeholder: placeholder,
      accessibilityHelp: accessibilityHelp,
      iconName: iconName,
      defaultLineNumber: defaultLineNumber,
      handler: handler
    )

    self.isMovableByWindowBackground = true
    self.isOpaque = false
    self.hasShadow = true
    self.backgroundColor = .clear
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
