//
//  TitleOnlyButton.swift
//
//  Created by cyan on 12/27/22.
//

import AppKit

public final class TitleOnlyButton: NonBezelButton {
  public let labelView = LabelView()

  public init(title: String? = nil, fontSize: Double? = nil) {
    super.init()

    labelView.stringValue = title ?? ""
    labelView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(labelView)

    if let fontSize {
      labelView.font = .systemFont(ofSize: fontSize)
    }

    NSLayoutConstraint.activate([
      labelView.centerXAnchor.constraint(equalTo: centerXAnchor),
      labelView.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])
  }

  override public func accessibilityLabel() -> String? {
    labelView.stringValue
  }
}
