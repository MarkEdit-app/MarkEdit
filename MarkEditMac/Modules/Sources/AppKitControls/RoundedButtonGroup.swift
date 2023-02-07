//
//  RoundedButtonGroup.swift
//
//  Created by cyan on 12/27/22.
//

import AppKit

/**
 Rounded button group with two buttons and a divider in the middle.
 */
open class RoundedButtonGroup: NSView {
  public var isEnabled: Bool = true {
    didSet {
      let alphaValue: Double = isEnabled ? 1.0 : 0.4
      leftButton.alphaValue = alphaValue
      rightButton.alphaValue = alphaValue
    }
  }

  private let leftButton: NSButton
  private let rightButton: NSButton
  private let dividerView = DividerView(color: .plainButtonBorder, hairlineWidth: false)

  public init(leftButton: NSButton, rightButton: NSButton) {
    self.leftButton = leftButton
    self.rightButton = rightButton
    super.init(frame: .zero)

    defer {
      isEnabled = false
    }

    wantsLayer = true
    layer?.masksToBounds = true
    layer?.borderWidth = 1
    layer?.cornerRadius = 5

    addSubview(leftButton)
    addSubview(rightButton)
    addSubview(dividerView)
  }

  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func layout() {
    super.layout()
    leftButton.frame = CGRect(
      x: 0,
      y: 0,
      width: frame.width * 0.5,
      height: frame.height
    )

    rightButton.frame = CGRect(
      x: frame.width * 0.5,
      y: 0,
      width: frame.width * 0.5,
      height: frame.height
    )

    dividerView.frame = CGRect(
      x: (frame.width - dividerView.length) * 0.5,
      y: 1.0,
      width: dividerView.length,
      height: frame.height - 2.0
    )
  }

  override public func updateLayer() {
    layer?.borderColor = NSColor.plainButtonBorder.cgColor
  }

  override public func hitTest(_ point: NSPoint) -> NSView? {
    isEnabled ? super.hitTest(point) : nil
  }
}
