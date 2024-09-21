//
//  BezelView.swift
//
//  Created by cyan on 8/20/23.
//

import AppKit

/**
 Draw bezels to replace the system one, due to different reasons.
 */
public final class BezelView: NSView {
  private let borderColor: NSColor

  public init(borderColor: NSColor = .separatorColor, cornerRadius: Double = 6) {
    self.borderColor = borderColor
    super.init(frame: .zero)

    wantsLayer = true
    layer?.cornerCurve = .continuous
    layer?.cornerRadius = cornerRadius
    layer?.borderWidth = 1
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
    layer?.borderColor = borderColor.cgColor
  }

  override public func hitTest(_ point: NSPoint) -> NSView? {
    // Only visually draw a bezel, not clickable
    nil
  }
}
