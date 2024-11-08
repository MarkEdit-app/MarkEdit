//
//  EditorFindButtons.swift
//
//  Created by cyan on 12/17/22.
//

import AppKit

public final class RoundedNavigateButtons: RoundedButtonGroup {
  private enum Constants {
    static let chevronLeft = "chevron.left"
    static let chevronRight = "chevron.right"
    static let iconWidth: Double = 9
    static let iconHeight: Double = 9
  }

  public init(
    leftAction: @escaping (() -> Void),
    rightAction: @escaping (() -> Void),
    leftAccessibilityLabel: String,
    rightAccessibilityLabel: String
  ) {
    let leftButton = IconOnlyButton(symbolName: Constants.chevronLeft, iconWidth: Constants.iconWidth, iconHeight: Constants.iconHeight, accessibilityLabel: leftAccessibilityLabel)
    leftButton.addAction(leftAction)

    let rightButton = IconOnlyButton(symbolName: Constants.chevronRight, iconWidth: Constants.iconWidth, iconHeight: Constants.iconHeight, accessibilityLabel: rightAccessibilityLabel)
    rightButton.addAction(rightAction)

    super.init(leftButton: leftButton, rightButton: rightButton)
    self.frame = CGRect(x: 0, y: 0, width: 72, height: 0)
  }
}
