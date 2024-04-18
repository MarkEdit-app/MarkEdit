//
//  EditorFindPanel.swift
//  MarkEditMac
//
//  Created by cyan on 12/16/22.
//

import AppKit
import AppKitControls
import MarkEditKit

@frozen enum EditorFindMode {
  /// Find panel is not visible.
  case hidden
  /// Find panel is visible, shows only find.
  case find
  /// Find panel is visible, shows both find and replace.
  case replace
}

@MainActor
protocol EditorFindPanelDelegate: AnyObject {
  func editorFindPanel(_ sender: EditorFindPanel, modeDidChange mode: EditorFindMode)
  func editorFindPanel(_ sender: EditorFindPanel, searchTermDidChange searchTerm: String)
  func editorFindPanel(_ sender: EditorFindPanel, performOperation operation: SearchOperation)
  func editorFindPanelDidChangeOptions(_ sender: EditorFindPanel)
  func editorFindPanelDidPressTabKey(_ sender: EditorFindPanel, isBacktab: Bool)
  func editorFindPanelDidClickNext(_ sender: EditorFindPanel)
  func editorFindPanelDidClickPrevious(_ sender: EditorFindPanel)
}

final class EditorFindPanel: EditorPanelView {
  weak var delegate: EditorFindPanelDelegate?
  var mode: EditorFindMode = .hidden
  var numberOfItems: Int = 0
  let searchField = LabeledSearchField()

  private(set) lazy var findButtons = EditorFindButtons(
    leftAction: { [weak self] in
      guard let self else { return }
      self.delegate?.editorFindPanelDidClickPrevious(self)
    },
    rightAction: { [weak self] in
      guard let self else { return }
      self.delegate?.editorFindPanelDidClickNext(self)
    }
  )

  private(set) lazy var doneButton = {
    let button = NSButton()
    button.bezelStyle = .roundRect

    button.attributedTitle = NSAttributedString(
      string: Localized.General.done,
      attributes: [.font: NSFont.systemFont(ofSize: 12)]
    )

    return button
  }()

  override init() {
    super.init()
    setUp()
  }
}

// MARK: - Exposed Methods

extension EditorFindPanel {
  func updateResult(numberOfItems: Int, emptyInput: Bool) {
    self.numberOfItems = numberOfItems
    searchField.updateLabel(text: emptyInput ? "" : "\(numberOfItems)")
    findButtons.isEnabled = numberOfItems > 0
  }
}
