//
//  EditorModuleUI.swift
//
//  Created by cyan on 2024/10/4.
//

import Foundation

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

  public func addMainMenu(id: String, title: String, items: [WebMenuItem]) {
    delegate?.editorUI(self, addMainMenu: id, title: title, items: items)
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
