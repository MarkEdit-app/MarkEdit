//
//  EditorFindPanel+UI.swift
//  MarkEditMac
//
//  Created by cyan on 12/25/22.
//

import AppKit

extension EditorFindPanel {
  private enum Constants {
    static let panelHeight: Double = 36
    static let panelPadding: Double = 6
  }

  func setUp() {
    frame = CGRect(x: 0, y: 0, width: 0, height: Constants.panelHeight)
    alphaValue = 0
    resetMenu()

    searchField.placeholderString = Localized.Search.find
    searchField.delegate = self
    searchField.target = self
    searchField.action = #selector(searchTermDidChange(_:))
    searchField.translatesAutoresizingMaskIntoConstraints = false
    addSubview(searchField)

    findButtons.translatesAutoresizingMaskIntoConstraints = false
    addSubview(findButtons)

    doneButton.target = self
    doneButton.action = #selector(didClickDone(_:))
    doneButton.translatesAutoresizingMaskIntoConstraints = false
    addSubview(doneButton)

    NSLayoutConstraint.activate([
      doneButton.centerYAnchor.constraint(equalTo: centerYAnchor),
      doneButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.panelPadding),

      findButtons.centerYAnchor.constraint(equalTo: centerYAnchor),
      findButtons.heightAnchor.constraint(equalTo: doneButton.heightAnchor),
      findButtons.widthAnchor.constraint(equalToConstant: findButtons.frame.width),
      findButtons.trailingAnchor.constraint(equalTo: doneButton.leadingAnchor, constant: -Constants.panelPadding),

      searchField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.panelPadding),
      searchField.trailingAnchor.constraint(equalTo: findButtons.leadingAnchor, constant: -Constants.panelPadding),
      searchField.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])
  }
}

// MARK: - Private

private extension EditorFindPanel {
  @objc func searchTermDidChange(_ sender: NSTextField) {
    delegate?.editorFindPanel(self, searchTermDidChange: sender.stringValue)
  }

  @objc func didClickDone(_ sender: NSButton) {
    delegate?.editorFindPanel(self, modeDidChange: .hidden)
  }
}
