//
//  LabeledSearchField.swift
//
//  Created by cyan on 12/19/22.
//

import AppKit
import AppKitExtensions

public final class LabeledSearchField: NSSearchField {
  private let modernStyle: Bool
  private let bezelView = BezelView(cornerRadius: Constants.bezelCornerRadius)

  private let labelView = {
    let label = LabelView(frame: .zero)
    label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
    label.textColor = .secondaryLabelColor
    return label
  }()

  public init(modernStyle: Bool) {
    self.modernStyle = modernStyle
    super.init(frame: .zero)

    usesSingleLineMode = false
    focusRingType = .exterior

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

    // To completely clip the unnecessary capsule-style border
    if modernStyle {
      #if DEBUG
        var hasAppKitSearchField = false
      #endif

      enumerateDescendants { view in
        if view.className.contains("AppKitSearchField") {
          #if DEBUG
            hasAppKitSearchField = true
          #endif
          view.layer?.cornerRadius = view.frame.height * 0.5
        }
      }

      #if DEBUG
        assert(hasAppKitSearchField, "Missing AppKitSearchField in NSSearchField")
      #endif
    }
  }

  override public func draw(_ dirtyRect: NSRect) {
    // Ignore the bezel and background color by only drawing interior
    cell?.drawInterior(withFrame: bounds, in: self)
  }

  override public func drawFocusRingMask() {
    // Custom focus ring drawing mostly because macOS Tahoe needs this
    NSBezierPath(
      roundedRect: bounds,
      xRadius: Constants.bezelCornerRadius,
      yRadius: Constants.bezelCornerRadius
    ).fill()
  }

  public func updateLabel(text: String) {
    labelView.stringValue = text
    labelView.isHidden = text.isEmpty
    needsLayout = true
  }
}

// MARK: - Private

private extension LabeledSearchField {
  enum Constants {
    static let bezelCornerRadius: Double = 6.0
  }
}
