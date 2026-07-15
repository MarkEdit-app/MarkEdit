//
//  LabelView.swift
//
//  Created by cyan on 12/19/22.
//

import AppKit

public final class LabelView: NSTextField {
  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    isBordered = false
    isEditable = false
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
