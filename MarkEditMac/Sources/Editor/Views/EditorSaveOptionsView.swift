//
//  EditorSaveOptionsView.swift
//  MarkEditMac
//
//  Created by cyan on 12/17/24.
//

import AppKit

/**
 Accessory view used in NSSavePanel to provide additional options.
 */
final class EditorSaveOptionsView: NSView {
  private weak var panel: NSSavePanel?

  init(panel: NSSavePanel) {
    self.panel = panel
    super.init(frame: .zero)

    let label = NSTextField(labelWithString: Localized.Document.filenameExtension)
    label.sizeToFit()
    addSubview(label)

    let picker = NSPopUpButton()
    picker.target = self
    picker.action = #selector(selectionDidChange(_:))

    NewFilenameExtension.allCases.forEach {
      picker.addItem(withTitle: $0.rawValue)
    }

    if let index = NewFilenameExtension.allCases.firstIndex(of: AppPreferences.General.newFilenameExtension) {
      picker.selectItem(at: index)
    }

    picker.sizeToFit()
    addSubview(picker)

    frame = CGRect(
      origin: .zero,
      size: CGSize(
        width: label.frame.width + picker.frame.width + 2,
        height: picker.frame.height + 10
      )
    )

    label.setFrameOrigin(CGPoint(x: 0, y: (frame.height - label.frame.height) * 0.5))
    picker.setFrameOrigin(CGPoint(x: label.frame.maxX + 2, y: (frame.height - picker.frame.height) * 0.5 - 1.5))
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: - Private

private extension EditorSaveOptionsView {
  @objc func selectionDidChange(_ sender: NSPopUpButton) {
    let filenameExtension = NewFilenameExtension.allCases[sender.indexOfSelectedItem]
    let allowsOtherFileTypes = panel?.allowsOtherFileTypes == true

    panel?.allowsOtherFileTypes = false // Must turn this off temporarily to enforce the file type
    panel?.allowedContentTypes = [filenameExtension.uniformType]

    DispatchQueue.main.async {
      self.panel?.allowsOtherFileTypes = allowsOtherFileTypes
    }
  }
}
