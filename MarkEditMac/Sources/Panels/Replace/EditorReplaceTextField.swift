//
//  EditorReplaceTextField.swift
//  MarkEditMac
//
//  Created by cyan on 8/20/23.
//

import AppKit
import AppKitControls

final class EditorReplaceTextField: NSTextField, @unchecked Sendable {
  private let bezelView = BezelView()

  init() {
    super.init(frame: .zero)
    usesSingleLineMode = false
    bezelStyle = .roundedBezel
    placeholderString = Localized.Search.replace
    addSubview(bezelView)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layout() {
    super.layout()
    bezelView.frame = bounds
  }

  override func draw(_ dirtyRect: NSRect) {
    // Ignore the bezel and background color by only drawing interior
    cell?.drawInterior(withFrame: bounds, in: self)
  }
}
