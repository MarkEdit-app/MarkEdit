//
//  NonBezelButton.swift
//
//  Created by cyan on 12/17/22.
//

import AppKit

public class NonBezelButton: NSButton {
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

    if isHighlighted {
      NSColor.plainButtonHighlighted.setFill()
      rectPath.fill()
    }
  }

  override public func resetCursorRects() {
    addCursorRect(bounds, cursor: .arrow)
  }
}
