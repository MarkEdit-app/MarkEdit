//
//  TableRowWrapper.swift
//
//  Created by cyan on 7/15/26.
//

import AppKit

/// Table row view that draws a bottom hairline separator, inset by a horizontal margin.
public final class TableRowWrapper: NSTableRowView {
  public var showsSeparator = true {
    didSet {
      separator.isHidden = !showsSeparator
    }
  }

  private let horizontalMargin: Double
  private let separator = DividerView(hairlineWidth: true)

  public init(horizontalMargin: Double) {
    self.horizontalMargin = horizontalMargin
    super.init(frame: .zero)
    addSubview(separator)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func layout() {
    super.layout()

    separator.frame = CGRect(
      x: horizontalMargin,
      y: isFlipped ? (bounds.maxY - separator.length) : bounds.minY,
      width: max(0, bounds.width - horizontalMargin * 2),
      height: separator.length
    )
  }
}
