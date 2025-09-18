//
//  EditorModuleAPI.swift
//
//  Created by cyan on 10/4/24.
//

import Foundation
import CryptoKit

#if os(macOS)
  import AppKit
#endif

@MainActor
public protocol EditorModuleAPIDelegate: AnyObject {
  func editorAPIGetFileURL(_ sender: EditorModuleAPI) -> URL?
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
  func editorAPI(_ sender: EditorModuleAPI, showSavePanel data: Data, fileName: String?) -> Bool
}

public final class EditorModuleAPI: NativeModuleAPI {
  private weak var delegate: EditorModuleAPIDelegate?

  public init(delegate: EditorModuleAPIDelegate) {
    self.delegate = delegate
  }

  public func getFileInfo() async -> String? {
    guard let fileURL = delegate?.editorAPIGetFileURL(self) else {
      return nil
    }

    let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
    Logger.assert(attributes != nil, "Cannot get file attributes of: \(fileURL)")

    let json: [String: Any] = [
      "filePath": fileURL.path,
      "fileSize": Double(attributes?[.size] as? Int64 ?? 0),
      "creationDate": (attributes?[.creationDate] as? Date ?? .distantPast).timeIntervalSince1970,
      "modificationDate": (attributes?[.modificationDate] as? Date ?? .distantPast).timeIntervalSince1970,
    ]

    return try? JSONSerialization.data(withJSONObject: json).toString()
  }

  public func getPasteboardItems() async -> String? {
  #if os(macOS)
    let pasteboard = NSPasteboard.general
    let types = pasteboard.types ?? []

    let json: [[String: String]] = types.compactMap { type in
      guard let data = pasteboard.data(forType: type) else {
        return nil
      }

      var dict = [
        "type": type.rawValue,
        "data": data.base64EncodedString(),
      ]

      dict["string"] = data.toString()
      return dict
    }

    return try? JSONSerialization.data(withJSONObject: json).toString()
  #else
    Logger.assertFail("Missing implementation, consider using web api directly")
    return []
  #endif
  }

  public func getPasteboardString() async -> String? {
  #if os(macOS)
    return NSPasteboard.general.string(forType: .string)
  #else
    Logger.assertFail("Missing implementation, consider using web api directly")
    return nil
  #endif
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

  public func showAlert(title: String?, message: String?, buttons: [String]?) async -> Int {
    delegate?.editorAPI(self, alertWith: title, message: message, buttons: buttons) ?? 0
  }

  public func showTextBox(title: String?, placeholder: String?, defaultValue: String?) async -> String? {
    delegate?.editorAPI(self, showTextBox: title, placeholder: placeholder, defaultValue: defaultValue)
  }

  public func showSavePanel(options: SavePanelOptions) async -> Bool {
    let data: Data = {
      if let source = options.data, let data = Data(base64Encoded: source, options: .ignoreUnknownCharacters) {
        return data
      }

      if let source = options.string, let data = source.data(using: .utf8) {
        return data
      }

      return Data()
    }()

    return delegate?.editorAPI(self, showSavePanel: data, fileName: options.fileName) == true
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
