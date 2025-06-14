//
//  NonBezelButton.swift
//
//  Created by cyan on 12/17/22.
//

import AppKit

public class NonBezelButton: NSButton {
  public var modernStyle = false
  public var modernCornerRadius: Double = 0
  public var modernStateChanged: ((_ isHighlighted: Bool) -> Void)?

  override init(frame: CGRect) {
    super.init(frame: frame)
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

    // Classic style:
    //  - Default: clear background
    //  - Highlighted: light gray background
    //
    // Modern style:
    //  - Default: light gray background
    //  - Highlighted: slightly darker light gray, rounded corner

    if modernStyle {
      modernStateChanged?(isHighlighted)
      NSColor.modernButtonBackground.setFill()
      rectPath.fill()
    }

    if isHighlighted {
      if modernStyle {
        NSBezierPath(
          roundedRect: bounds,
          xRadius: modernCornerRadius,
          yRadius: modernCornerRadius
        ).fill()
      } else {
        NSColor.plainButtonHighlighted.setFill()
        rectPath.fill()
      }
    }
  }

  override public func resetCursorRects() {
    addCursorRect(bounds, cursor: .arrow)
  }
}
