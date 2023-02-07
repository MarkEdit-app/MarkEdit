//
//  EditorReplaceButtons.swift
//  MarkEditMac
//
//  Created by cyan on 12/27/22.
//

import AppKit
import AppKitControls

final class EditorReplaceButtons: RoundedButtonGroup {
  init(leftAction: @escaping (() -> Void), rightAction: @escaping (() -> Void)) {
    let leftButton = TitleOnlyButton(title: Localized.Search.replace)
    leftButton.addAction(leftAction)

    let rightButton = TitleOnlyButton(title: Localized.General.all)
    rightButton.addAction(rightAction)

    super.init(leftButton: leftButton, rightButton: rightButton)
  }
}
