//
//  EditorStatusView.swift
//  MarkEditMac
//
//  Created by cyan on 1/16/23.
//

import AppKit
import AppKitControls
import MarkEditKit

// [macOS 26] Clean these up

private protocol ButtonLabeling {
  var labelView: LabelView { get }
}

extension TitleOnlyButton: ButtonLabeling {}

/**
 To indicate the current line, column and length of selection.
 */
final class EditorStatusView: NSView, BackgroundTheming {
  private let button: NSButton & ButtonLabeling = {
    if AppDesign.modernStyle {
      return GlassButton()
    }

    return TitleOnlyButton(font: Constants.titleFont)
  }()

  init(handler: @escaping () -> Void) {
    super.init(frame: .zero)
    self.toolTip = Localized.Document.gotoLineLabel

    button.addAction(handler)
    addSubview(button)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layout() {
    super.layout()
    button.frame = bounds
  }

  override func updateLayer() {
    if button is GlassButton {
      return
    }

    layer?.borderWidth = 1
    layer?.cornerRadius = 3
    layer?.cornerCurve = .continuous
    layer?.borderColor = NSColor.plainButtonBorder.cgColor
  }

  func updateLineColumn(_ info: LineColumnInfo) {
    let title = {
      // Don't localize the labels
      let lineColumn = "Ln \(info.lineNumber), Col \(info.columnText.count + 1)"
      if info.selectionText.isEmpty {
        return lineColumn
      } else {
        return "\(lineColumn) (\(info.selectionText.count))"
      }
    }()

    let label = button.labelView
    label.stringValue = title
    label.sizeToFit()

    self.frame = label.bounds.insetBy(dx: -4, dy: AppDesign.modernStyle ? -4 : -2)
    self.needsLayout = true
  }
}

// MARK: - Accessibility

extension EditorStatusView {
  override var canBecomeKeyView: Bool {
    true
  }

  override var acceptsFirstResponder: Bool {
    true
  }

  override func isAccessibilityElement() -> Bool {
    true
  }

  override func accessibilityRole() -> NSAccessibility.Role? {
    .button
  }

  override func accessibilityLabel() -> String? {
    button.labelView.stringValue
  }

  override func accessibilityPerformPress() -> Bool {
    button.performClick(nil)
    return true
  }
}

// MARK: - Private

private enum Constants {
  static let titleFont: NSFont = .monospacedDigitSystemFont(ofSize: 11, weight: .regular)
}

private class GlassButton: NSButton, ButtonLabeling {
  fileprivate let labelView = LabelView()

  override init(frame frameRect: CGRect) {
    super.init(frame: frameRect)
    font = .systemFont(ofSize: 7) // To make the button smaller
    title = "" // Clear the title and bezel

    labelView.font = Constants.titleFont
    labelView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(labelView)
    NSLayoutConstraint.activate([
      labelView.centerXAnchor.constraint(equalTo: centerXAnchor),
      labelView.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])

    if #available(macOS 26.0, *) {
      bezelStyle = .glass
    }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func resetCursorRects() {
    addCursorRect(bounds, cursor: .arrow)
  }
}
