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

  // To render custom icons in modern style due to the unwanted bezel added by Apple
  private lazy var searchIconView = CustomIconView()
  private lazy var cancelIconView: CustomIconView = {
    let view = CustomIconView()
    view.isHidden = true

    return view
  }()

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
      x: (cancelButtonBounds.minX - labelView.frame.width) - 2.0,
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

    if modernStyle {
      // To completely remove the unnecessary capsule-style border
      if let view = modernBezelView {
        renderCustomIcons(modernBezel: view)
      } else {
        #if DEBUG
          assertionFailure("Missing AppKitSearchField in NSSearchField")
        #endif
      }
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

  override public var stringValue: String {
    get {
      super.stringValue
    }
    set {
      super.stringValue = newValue
      updateCustomCancelIcon()
    }
  }

  override public func textDidChange(_ notification: Notification) {
    super.textDidChange(notification)
    updateCustomCancelIcon()
  }

  public func updateLabel(text: String) {
    labelView.stringValue = text
    labelView.isHidden = text.isEmpty
    needsLayout = true
  }

  public func setSearchIconColor(_ tintColor: NSColor?) {
    let buttonCell = searchButtonCell
    let iconImage = buttonCell?.image?.copy() as? NSImage
    iconImage?.setTintColor(tintColor)

    // Must clear first
    buttonCell?.image = nil
    buttonCell?.image = iconImage

    if modernStyle {
      searchIconView.image = nil
      searchIconView.image = iconImage
    }

    needsDisplay = true
  }
}

// MARK: - Private

private extension LabeledSearchField {
  enum Constants {
    static let bezelCornerRadius: Double = 6.0
  }

  func renderCustomIcons(modernBezel: NSView) {
    // This is used for styling only, user interactions are not handled here
    modernBezel.isHidden = true

    searchIconView.image = searchButtonCell?.image
    searchIconView.frame = customIconBounds(for: searchButtonBounds)

    cancelIconView.image = cancelButtonCell?.image
    cancelIconView.frame = customIconBounds(for: cancelButtonBounds)

    if searchIconView.superview == nil {
      addSubview(searchIconView)
    }

    if cancelIconView.superview == nil {
      addSubview(cancelIconView)
    }

    updateCustomCancelIcon()
  }

  func updateCustomCancelIcon() {
    guard modernStyle else {
      return
    }

    cancelIconView.isHidden = stringValue.isEmpty
  }

  func customIconBounds(for cellRect: CGRect) -> CGRect {
    CGRect(x: cellRect.minX, y: 0, width: cellRect.width, height: frame.height)
  }
}

private class CustomIconView: NSImageView {
  override func hitTest(_ point: NSPoint) -> NSView? {
    nil
  }

  override func isAccessibilityElement() -> Bool {
    false
  }

  override func accessibilityRole() -> NSAccessibility.Role? {
    .none
  }
}
