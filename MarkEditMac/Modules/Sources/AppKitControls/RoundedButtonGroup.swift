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
      leftButton.isEnabled = isEnabled
      leftButton.alphaValue = alphaValue
      rightButton.isEnabled = isEnabled
      rightButton.alphaValue = alphaValue
    }
  }

  private let modernStyle: Bool
  private let leftButton: NSButton
  private let rightButton: NSButton
  private let dividerView = DividerView(color: .plainButtonBorder, hairlineWidth: false)

  public init(modernStyle: Bool, leftButton: NonBezelButton, rightButton: NonBezelButton) {
    self.modernStyle = modernStyle
    self.leftButton = leftButton
    self.rightButton = rightButton
    super.init(frame: .zero)

    defer {
      isEnabled = false
    }

    wantsLayer = true
    layer?.masksToBounds = true
    layer?.borderWidth = modernStyle ? 0 : 1
    layer?.cornerRadius = Constants.cornerRadius

    addSubview(leftButton)
    addSubview(rightButton)
    addSubview(dividerView)

    // Create a "segmented control"-like highlighted state
    if modernStyle {
      for button in [leftButton, rightButton] {
        button.modernStyle = true
        button.modernCornerRadius = Constants.cornerRadius
        button.modernStateChanged = { [weak self] isHighlighted in
          self?.dividerView.isHidden = isHighlighted
        }
      }
    }
  }

  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func setBackgroundColor(_ color: NSColor) {
    leftButton.layerBackgroundColor = color
    rightButton.layerBackgroundColor = color
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

    let margin: Double = modernStyle ? 4 : 1
    dividerView.frame = CGRect(
      x: (frame.width - dividerView.length) * 0.5,
      y: margin,
      width: dividerView.length,
      height: frame.height - margin * 2
    )
  }

  override public func updateLayer() {
    layer?.borderColor = NSColor.plainButtonBorder.cgColor
  }

  override public func hitTest(_ point: NSPoint) -> NSView? {
    isEnabled ? super.hitTest(point) : nil
  }
}

// MARK: - Private

private extension RoundedButtonGroup {
  enum Constants {
    static let cornerRadius: Double = 5
  }
}
