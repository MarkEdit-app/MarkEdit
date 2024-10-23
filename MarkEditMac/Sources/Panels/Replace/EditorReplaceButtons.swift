//
//  EditorReplaceButtons.swift
//  MarkEditMac
//
//  Created by cyan on 12/27/22.
//

import AppKit
import AppKitControls

final class EditorReplaceButtons: RoundedButtonGroup, @unchecked Sendable {
  private enum Constants {
    static let fontSize: Double = 12
  }

  init(leftAction: @escaping (() -> Void), rightAction: @escaping (() -> Void)) {
    let leftButton = TitleOnlyButton(title: Localized.Search.replace, fontSize: Constants.fontSize)
    leftButton.addAction(leftAction)

    let rightButton = TitleOnlyButton(title: Localized.General.all, fontSize: Constants.fontSize)
    rightButton.addAction(rightAction)

    super.init(leftButton: leftButton, rightButton: rightButton)
  }
}
