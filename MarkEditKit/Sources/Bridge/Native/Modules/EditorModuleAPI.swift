//
//  EditorModuleAPI.swift
//
//  Created by cyan on 10/4/24.
//

import Foundation
import CryptoKit

@MainActor
public protocol EditorModuleAPIDelegate: AnyObject {
  func editorAPI(_ sender: EditorModuleAPI, addMainMenuItems items: [(String, WebMenuItem)])
  func editorAPI(_ sender: EditorModuleAPI, showContextMenu items: [WebMenuItem], location: WebPoint)
  func editorAPI(
    _ sender: EditorModuleAPI,
    alertWith title: String?,
    message: String?,
    buttons: [String]?
  ) -> Int
  func editorAPI(
    _ sender: EditorModuleAPI,
    showTextBox title: String?,
    placeholder: String?,
    defaultValue: String?
  ) -> String?
}

public final class EditorModuleAPI: NativeModuleAPI {
  private weak var delegate: EditorModuleAPIDelegate?

  public init(delegate: EditorModuleAPIDelegate) {
    self.delegate = delegate
  }

  public func addMainMenuItems(items: [WebMenuItem]) {
    delegate?.editorAPI(self, addMainMenuItems: items.map { item in
      let hash = SHA256.hash(data: Data(item.uniqueID.utf8))
      let id = hash.map { String(format: "%02x", $0) }.joined()
      return (id, item)
    })
  }

  public func showContextMenu(items: [WebMenuItem], location: WebPoint) {
    delegate?.editorAPI(self, showContextMenu: items, location: location)
  }

  public func showAlert(title: String?, message: String?, buttons: [String]?) -> Int {
    delegate?.editorAPI(self, alertWith: title, message: message, buttons: buttons) ?? 0
  }

  public func showTextBox(title: String?, placeholder: String?, defaultValue: String?) -> String? {
    delegate?.editorAPI(self, showTextBox: title, placeholder: placeholder, defaultValue: defaultValue)
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
