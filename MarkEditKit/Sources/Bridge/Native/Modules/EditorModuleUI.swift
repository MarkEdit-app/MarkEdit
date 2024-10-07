//
//  EditorModuleUI.swift
//
//  Created by cyan on 2024/10/4.
//

import Foundation
import CryptoKit

@MainActor
public protocol EditorModuleUIDelegate: AnyObject {
  func editorUI(_ sender: EditorModuleUI, addMainMenuItems items: [(String, WebMenuItem)])
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

  public func addMainMenuItems(items: [WebMenuItem]) {
    delegate?.editorUI(self, addMainMenuItems: items.map { item in
      let hash = SHA256.hash(data: Data(item.uniqueID.utf8))
      let id = hash.map { String(format: "%02x", $0) }.joined()
      return (id, item)
    })
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
