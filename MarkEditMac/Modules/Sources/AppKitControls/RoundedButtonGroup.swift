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
  public var isEnabled: Bool = false {
    didSet {
      updateAppearance()
    }
  }

  private let leftButton: NSButton
  private let rightButton: NSButton
  private let dividerView = DividerView(color: .plainButtonBorder)

  public init(leftButton: NonBezelButton, rightButton: NonBezelButton) {
    self.leftButton = leftButton
    self.rightButton = rightButton
    super.init(frame: .zero)

    wantsLayer = true
    layer?.masksToBounds = true
    layer?.cornerRadius = Constants.cornerRadius

    addSubview(leftButton)
    addSubview(rightButton)
    addSubview(dividerView)

    // Create a "segmented control"-like highlighted state
    for button in [leftButton, rightButton] {
      button.modernCornerRadius = Constants.cornerRadius
      button.modernStateChanged = { [weak self] isHighlighted in
        self?.dividerView.isHidden = isHighlighted
      }
    }

    // Half-rounded corners for the focus ring
    leftButton.focusRingRadius = Constants.cornerRadius
    leftButton.focusRingCorners = .left
    rightButton.focusRingRadius = Constants.cornerRadius
    rightButton.focusRingCorners = .right

    isEnabled = false
    updateAppearance()
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

    let margin: Double = 4
    dividerView.frame = CGRect(
      x: (frame.width - dividerView.length) * 0.5,
      y: margin,
      width: dividerView.length,
      height: frame.height - margin * 2
    )
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

  func updateAppearance() {
    let alphaValue: Double = isEnabled ? 1.0 : 0.4
    leftButton.isEnabled = isEnabled
    leftButton.alphaValue = alphaValue
    rightButton.isEnabled = isEnabled
    rightButton.alphaValue = alphaValue
  }
}
