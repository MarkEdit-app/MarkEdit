//
//  DividerView.swift
//
//  Created by cyan on 12/17/22.
//

import AppKit

/**
 Hairline-width divider, it requires manual layout to be correctly rendered.
 */
public final class DividerView: NSView {
  public var length: Double {
    hairlineWidth ? (1.0 / (window?.screen?.backingScaleFactor ?? 1)) : 1
  }

  private let color: NSColor
  private let hairlineWidth: Bool

  public init(color: NSColor = .separatorColor, hairlineWidth: Bool = true) {
    self.color = color
    self.hairlineWidth = hairlineWidth
    super.init(frame: .zero)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func updateLayer() {
    layerBackgroundColor = color
  }
}
