//
//  EditorStatusView.swift
//  MarkEditMac
//
//  Created by cyan on 1/16/23.
//

import AppKit
import AppKitControls
import MarkEditKit

/**
 To indicate the current line, column and length of selection.
 */
final class EditorStatusView: NSView, BackgroundTheming {
  private let button = TitleOnlyButton(fontSize: 11)

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
    layer?.borderWidth = 1
    layer?.cornerRadius = AppDesign.modernStyle ? 6 : 3
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

    let insets = AppDesign.modernStyle ? CGPoint(x: -5, y: -3) : CGPoint(x: -4, y: -2)
    self.frame = label.bounds.insetBy(dx: insets.x, dy: insets.y)
    self.needsLayout = true
  }
}

// MARK: - Accessibility

extension EditorStatusView {
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
