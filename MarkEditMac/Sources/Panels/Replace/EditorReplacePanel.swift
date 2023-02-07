//
//  EditorReplacePanel.swift
//  MarkEditMac
//
//  Created by cyan on 12/26/22.
//

import AppKit

protocol EditorReplacePanelDelegate: AnyObject {
  func editorReplacePanel(_ sender: EditorReplacePanel, replacementDidChange replacement: String)
  func editorReplacePanelDidClickReplaceNext(_ sender: EditorReplacePanel)
  func editorReplacePanelDidClickReplaceAll(_ sender: EditorReplacePanel)
}

final class EditorReplacePanel: EditorPanelView {
  weak var delegate: EditorReplacePanelDelegate?

  var layoutInfo: (textFieldFrame: CGRect, buttonHeight: CGFloat) = (.zero, 0) {
    didSet {
      needsLayout = true
    }
  }

  private(set) lazy var textField = {
    let textField = NSTextField()
    textField.placeholderString = Localized.Search.replace
    textField.bezelStyle = .roundedBezel
    textField.delegate = self
    return textField
  }()

  private lazy var replaceButtons = EditorReplaceButtons(
    leftAction: { [weak self] in
      guard let self else { return }
      self.delegate?.editorReplacePanelDidClickReplaceNext(self)
    },
    rightAction: { [weak self] in
      guard let self else { return }
      self.delegate?.editorReplacePanelDidClickReplaceAll(self)
    }
  )

  override init() {
    super.init()
    alphaValue = 0
    isHidden = true

    addSubview(textField)
    addSubview(replaceButtons)
  }

  override func layout() {
    super.layout()
    let paddingX = layoutInfo.textFieldFrame.minX
    let paddingY = layoutInfo.textFieldFrame.minY

    textField.frame = CGRect(
      x: paddingX,
      y: paddingY,
      width: layoutInfo.textFieldFrame.width,
      height: layoutInfo.textFieldFrame.height
    )

    replaceButtons.frame = CGRect(
      x: textField.frame.maxX + paddingX,
      y: paddingY + (layoutInfo.textFieldFrame.height - layoutInfo.buttonHeight) * 0.5,
      width: frame.width - textField.frame.width - paddingX * 3,
      height: layoutInfo.buttonHeight
    )

    mirrorImmediateSubviewsIfNeeded()
  }
}

// MARK: - Exposed Methods

extension EditorReplacePanel {
  func updateResult(numberOfItems: Int) {
    replaceButtons.isEnabled = numberOfItems > 0
  }
}

// MARK: - NSTextFieldDelegate

extension EditorReplacePanel: NSTextFieldDelegate {
  func controlTextDidChange(_ notification: Notification) {
    delegate?.editorReplacePanel(self, replacementDidChange: textField.stringValue)
  }

  func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
    if selector == #selector(insertNewline(_:)) && replaceButtons.isEnabled {
      delegate?.editorReplacePanelDidClickReplaceNext(self)
      return true
    }

    return false
  }
}
