//
//  IconOnlyButton.swift
//
//  Created by cyan on 12/17/22.
//

import AppKit

public final class IconOnlyButton: NonBezelButton {
  public init(symbolName: String, accessibilityLabel: String? = nil) {
    super.init()
    toolTip = accessibilityLabel

    if let iconImage = NSImage(systemSymbolName: symbolName, accessibilityDescription: accessibilityLabel) {
      let iconView = NSImageView(image: iconImage)
      iconView.contentTintColor = .labelColor
      iconView.translatesAutoresizingMaskIntoConstraints = false
      addSubview(iconView)

      NSLayoutConstraint.activate([
        iconView.widthAnchor.constraint(equalToConstant: iconImage.size.width),
        iconView.heightAnchor.constraint(equalToConstant: iconImage.size.height),
        iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
        iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
      ])
    }
  }
}
