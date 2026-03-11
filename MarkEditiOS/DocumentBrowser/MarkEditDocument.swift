//
//  MarkEditDocument.swift
//  MarkEditiOS
//
//  UIDocument subclass for markdown files.
//  Handles open / read / write / autosave lifecycle.
//

import UIKit

final class MarkEditDocument: UIDocument {
  /// Plain text content of the document.
  var stringValue: String = ""

  // MARK: - UIDocument overrides

  /// Encode the current string value to UTF-8 data for saving.
  override func contents(forType typeName: String) throws -> Any {
    return stringValue.data(using: .utf8) ?? Data()
  }

  /// Decode incoming data (from disk or iCloud) into stringValue.
  override func load(fromContents contents: Any, ofType typeName: String?) throws {
    guard let data = contents as? Data else { return }
    stringValue = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) ?? ""
  }

  // MARK: - Helpers

  /// Display name without the file extension.
  var displayName: String {
    fileURL.deletingPathExtension().lastPathComponent
  }
}
