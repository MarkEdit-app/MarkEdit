//
//  EditorFindPanel.swift
//  MarkEditMac
//
//  Created by cyan on 12/16/22.
//

import AppKit
import AppKitControls
import MarkEditKit

enum EditorFindMode {
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
  func editorFindPanelOperationsMenuItem(_ sender: EditorFindPanel) -> NSMenuItem?
  func editorFindPanelDidChangeOptions(_ sender: EditorFindPanel)
  func editorFindPanelDidPressTabKey(_ sender: EditorFindPanel, isBacktab: Bool)
  func editorFindPanelDidClickNext(_ sender: EditorFindPanel)
  func editorFindPanelDidClickPrevious(_ sender: EditorFindPanel)
}

final class EditorFindPanel: EditorPanelView {
  weak var delegate: EditorFindPanelDelegate?
  var mode: EditorFindMode = .hidden
  var numberOfItems: Int = 0
  let searchField = LabeledSearchField(modernStyle: AppDesign.modernStyle)

  private(set) lazy var findButtons = RoundedNavigateButtons(
    modernStyle: AppDesign.modernStyle,
    leftAction: { [weak self] in
      guard let self else { return }
      self.delegate?.editorFindPanelDidClickPrevious(self)
    },
    rightAction: { [weak self] in
      guard let self else { return }
      self.delegate?.editorFindPanelDidClickNext(self)
    },
    leftAccessibilityLabel: Localized.General.previous,
    rightAccessibilityLabel: Localized.General.next
  )

  private(set) lazy var doneButton = {
    let button = AquaFocusRingButton()
    button.bezelStyle = .accessoryBarAction

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
  func updateResult(counter: SearchCounterInfo, emptyInput: Bool) {
    numberOfItems = counter.numberOfItems
    findButtons.isEnabled = numberOfItems > 0

    if emptyInput {
      searchField.updateLabel(text: "")
    } else if numberOfItems > 0 && counter.currentIndex >= 0 {
      let text = String(format: Localized.Search.indexOfMatches, counter.currentIndex + 1, numberOfItems)
      searchField.updateLabel(text: text)
    } else {
      searchField.updateLabel(text: "\(numberOfItems)")
    }

    resetMenu()
  }

  func clearCounter() {
    let info = SearchCounterInfo(numberOfItems: 0, currentIndex: -1)
    updateResult(counter: info, emptyInput: true)
  }
}
