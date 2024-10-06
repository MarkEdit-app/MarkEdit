//
//  EditorModuleUI.swift
//
//  Created by cyan on 2024/10/4.
//

import Foundation
import CryptoKit

@MainActor
public protocol EditorModuleUIDelegate: AnyObject {
  func editorUI(_ sender: EditorModuleUI, addMainMenu menuID: String, title: String, items: [WebMenuItem])
  func editorUI(_ sender: EditorModuleUI, showContextMenu items: [WebMenuItem], location: WebPoint)
  func editorUI(
    _ sender: EditorModuleUI,
    alertWith title: String?,
    message: String?,
    buttons: [String]?
  ) -> Int
  func editorUI(
    _ sender: EditorModuleUI,
    showTextBox title: String?,
    placeholder: String?,
    defaultValue: String?
  ) -> String?
}

public final class EditorModuleUI: NativeModuleUI {
  private weak var delegate: EditorModuleUIDelegate?

  public init(delegate: EditorModuleUIDelegate) {
    self.delegate = delegate
  }

  public func addMainMenu(title: String, items: [WebMenuItem]) {
    let identifiers = ([title] + items.map { $0.uniqueID }).joined(separator: " | ")
    let hash = SHA256.hash(data: Data(identifiers.utf8))
    let menuID = hash.map { String(format: "%02x", $0) }.joined()

    delegate?.editorUI(
      self,
      addMainMenu: menuID,
      title: title,
      items: items
    )
  }

  public func showContextMenu(items: [WebMenuItem], location: WebPoint) {
    delegate?.editorUI(self, showContextMenu: items, location: location)
  }

  public func showAlert(title: String?, message: String?, buttons: [String]?) -> Int {
    delegate?.editorUI(self, alertWith: title, message: message, buttons: buttons) ?? 0
  }

  public func showTextBox(title: String?, placeholder: String?, defaultValue: String?) -> String? {
    delegate?.editorUI(self, showTextBox: title, placeholder: placeholder, defaultValue: defaultValue)
  }
}

// MARK: - Private

private extension WebMenuItem {
  var uniqueID: String {
    [
      "\(separator)",
      title ?? "",
      key ?? "",
      "\(modifiers ?? [])",
      "[\((children ?? []).map { $0.uniqueID }.joined(separator: ", "))]",
    ].joined(separator: ", ")
  }
}
