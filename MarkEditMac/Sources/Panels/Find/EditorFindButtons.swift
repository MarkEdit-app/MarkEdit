//
//  EditorFindButtons.swift
//  MarkEditMac
//
//  Created by cyan on 12/17/22.
//

import AppKit
import AppKitControls

final class EditorFindButtons: RoundedButtonGroup {
  init(leftAction: @escaping (() -> Void), rightAction: @escaping (() -> Void)) {
    let leftButton = IconOnlyButton(symbolName: Icons.chevronLeft, accessibilityLabel: Localized.General.previous)
    leftButton.addAction(leftAction)

    let rightButton = IconOnlyButton(symbolName: Icons.chevronRight, accessibilityLabel: Localized.General.next)
    rightButton.addAction(rightAction)

    super.init(leftButton: leftButton, rightButton: rightButton)
    self.frame = CGRect(x: 0, y: 0, width: 72, height: 0)
  }
}
