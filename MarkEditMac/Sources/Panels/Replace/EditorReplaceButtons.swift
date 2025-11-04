//
//  EditorReplaceButtons.swift
//  MarkEditMac
//
//  Created by cyan on 12/27/22.
//

import AppKit
import AppKitControls

final class EditorReplaceButtons: RoundedButtonGroup {
  private enum Constants {
    static let font: NSFont = .systemFont(ofSize: 12)
  }

  init(leftAction: @escaping (() -> Void), rightAction: @escaping (() -> Void)) {
    let leftButton = TitleOnlyButton(title: Localized.Search.replace, font: Constants.font)
    leftButton.addAction(leftAction)

    let rightButton = TitleOnlyButton(title: Localized.General.all, font: Constants.font)
    rightButton.addAction(rightAction)

    super.init(modernStyle: AppDesign.modernStyle, leftButton: leftButton, rightButton: rightButton)
  }
}
