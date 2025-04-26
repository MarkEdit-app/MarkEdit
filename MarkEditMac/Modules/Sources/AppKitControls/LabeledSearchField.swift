//
//  LabeledSearchField.swift
//
//  Created by cyan on 12/19/22.
//

import AppKit
import AppKitExtensions

public final class LabeledSearchField: NSSearchField {
  private let bezelView = BezelView()

  private let labelView = {
    let label = LabelView(frame: .zero)
    label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
    label.textColor = .secondaryLabelColor
    return label
  }()

  override public init(frame: CGRect) {
    super.init(frame: frame)
    usesSingleLineMode = false
    addSubview(bezelView)
    addSubview(labelView)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func layout() {
    super.layout()
    bezelView.frame = bounds

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

  override public func draw(_ dirtyRect: NSRect) {
    // Ignore the bezel and background color by only drawing interior
    cell?.drawInterior(withFrame: bounds, in: self)
  }

  public func updateLabel(text: String) {
    labelView.stringValue = text
    labelView.isHidden = text.isEmpty
    needsLayout = true
  }
}
