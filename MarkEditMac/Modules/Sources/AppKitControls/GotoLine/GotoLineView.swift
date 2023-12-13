//
//  GotoLineView.swift
//
//  Created by cyan on 1/17/23.
//

import AppKit

final class GotoLineView: NSView {
  private enum Constants {
    static let cornerRadius: Double = 12
    static let padding: Double = 8
  }

  private let effectView: NSVisualEffectView = {
    let effectView = NSVisualEffectView()
    effectView.material = .popover

    return effectView
  }()

  private let textField: NSTextField = {
    let textField = NSTextField()
    textField.font = .systemFont(ofSize: 20, weight: .light)
    textField.focusRingType = .none
    textField.drawsBackground = false
    textField.isBezeled = false

    return textField
  }()

  private let handler: (Int) -> Void

  init(frame: CGRect, placeholder: String, accessibilityHelp: String, iconName: String, handler: @escaping (Int) -> Void) {
    self.handler = handler
    super.init(frame: frame)

    wantsLayer = true
    layer?.cornerCurve = .continuous
    layer?.cornerRadius = Constants.cornerRadius

    effectView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(effectView)

    let iconView = NSImageView(image: .with(symbolName: iconName, pointSize: 24, weight: .light))
    iconView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(iconView)

    textField.placeholderString = placeholder
    textField.setAccessibilityHelp(accessibilityHelp)
    textField.delegate = self
    textField.translatesAutoresizingMaskIntoConstraints = false
    addSubview(textField)

    NSLayoutConstraint.activate([
      effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
      effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
      effectView.topAnchor.constraint(equalTo: topAnchor),
      effectView.bottomAnchor.constraint(equalTo: bottomAnchor),

      iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.padding),
      iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
      iconView.heightAnchor.constraint(equalToConstant: iconView.frame.height),
      iconView.widthAnchor.constraint(equalToConstant: iconView.frame.width),

      textField.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: Constants.padding),
      textField.centerYAnchor.constraint(equalTo: centerYAnchor),
      textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.padding),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: - NSTextFieldDelegate

extension GotoLineView: NSTextFieldDelegate {
  func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
    switch selector {
    case #selector(insertNewline(_:)):
      performGotoLine()
      return true
    default:
      return false
    }
  }
}

// MARK: - Private

private extension GotoLineView {
  func performGotoLine() {
    // We don't know exactly how many lines we have, unreasonable values will fail silently
    guard let lineNumber = Int(textField.stringValue), lineNumber > 0 else {
      NSSound.beep()
      textField.currentEditor()?.selectAll(nil)
      return
    }

    handler(lineNumber)
    window?.orderOut(self)
  }
}
