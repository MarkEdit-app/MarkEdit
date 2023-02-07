//
//  LabeledSearchField.swift
//
//  Created by cyan on 12/19/22.
//

import AppKit
import AppKitExtensions

public final class LabeledSearchField: NSSearchField {
  private let labelView = {
    let label = LabelView()
    label.font = .systemFont(ofSize: 10)
    label.textColor = .secondaryLabelColor
    return label
  }()

  public init() {
    super.init(frame: .zero)
    addSubview(labelView)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func layout() {
    super.layout()

    labelView.sizeToFit()
    labelView.frame = CGRect(
      x: (frame.width - labelView.frame.width) - 25,
      y: (frame.height - labelView.frame.height) * 0.5,
      width: labelView.frame.width,
      height: labelView.frame.height
    )

    if let clipView {
      clipView.frame = CGRect(
        x: clipView.frame.minX,
        y: clipView.frame.minY,
        width: labelView.frame.minX - clipView.frame.minX,
        height: clipView.frame.height
      )
    }
  }

  public func updateLabel(text: String) {
    labelView.stringValue = text
    labelView.isHidden = text.isEmpty
    needsLayout = true
  }
}
