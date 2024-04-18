//
//  FontManagerDelegate.swift
//
//  Created by cyan on 1/30/23.
//

import AppKit

/**
 Shared delegate to handle font changes sent by NSFontManager.
 */
@MainActor
final class FontManagerDelegate {
  static let shared = FontManagerDelegate()
  var fontDidChange: ((NSFont) -> Void)?

  @objc func changeFont(_ sender: NSFontManager?) {
    guard let newFont = sender?.convert(.systemFont(ofSize: NSFont.systemFontSize)) else {
      return
    }

    fontDidChange?(newFont)
  }

  // MARK: - Private

  private init() {}
}
