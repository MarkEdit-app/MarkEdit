//
//  LabelView.swift
//
//  Created by cyan on 12/19/22.
//

import AppKit

public final class LabelView: NSTextField {
  init() {
    super.init(frame: .zero)
    backgroundColor = .clear
    isBordered = false
    isEditable = false
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
