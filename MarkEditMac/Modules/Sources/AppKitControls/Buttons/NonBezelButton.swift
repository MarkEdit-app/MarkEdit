//
//  NonBezelButton.swift
//
//  Created by cyan on 12/17/22.
//

import AppKit
import AppKitExtensions

public class NonBezelButton: NSButton {
  public var focusRingRadius: Double?
  public var focusRingCorners: NSBezierPath.Corners?
  public var modernCornerRadius: Double = 0
  public var modernStateChanged: ((_ isHighlighted: Bool) -> Void)?

  override init(frame: CGRect) {
    super.init(frame: frame)
    focusRingType = .exterior
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func draw(_ dirtyRect: CGRect) {
    super.draw(dirtyRect)
    layerBackgroundColor?.setFill()

    let rectPath = NSBezierPath(rect: bounds)
    rectPath.fill()

    //  - Default: light gray background
    //  - Highlighted: slightly darker light gray, rounded corner
    modernStateChanged?(isHighlighted)
    NSColor.modernButtonBackground.setFill()
    rectPath.fill()

    if isHighlighted {
      NSBezierPath(
        roundedRect: bounds,
        xRadius: modernCornerRadius,
        yRadius: modernCornerRadius
      ).fill()
    }
  }

  override public func drawFocusRingMask() {
    guard let focusRingRadius, let focusRingCorners else {
      return super.drawFocusRingMask()
    }

    NSBezierPath(roundedRect: bounds, radius: focusRingRadius, corners: focusRingCorners).fill()
  }

  override public func resetCursorRects() {
    addCursorRect(bounds, cursor: .arrow)
  }
}
