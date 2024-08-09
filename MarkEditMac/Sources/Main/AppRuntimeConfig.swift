//
//  AppRuntimeConfig.swift
//  MarkEditMac
//
//  Created by cyan on 2024/8/9.
//

import Foundation
import MarkEditKit

/// Preferences for pro users, not directly visible in the Settings panel.
///
/// The underlying file is stored as "settings.json" in AppCustomization.
enum AppRuntimeConfig {
  struct Definition: Codable {
    struct HotKey: Codable {
      let key: String
      let modifiers: [String]
    }

    // swiftlint:disable discouraged_optional_boolean

    let autoCharacterPairs: Bool?
    let indentParagraphs: Bool?
    let mainWindowHotKey: HotKey?

    // swiftlint:enable discouraged_optional_boolean

    enum CodingKeys: String, CodingKey {
      case autoCharacterPairs = "editor.autoCharacterPairs"
      case indentParagraphs = "editor.indentParagraphs"
      case mainWindowHotKey = "general.mainWindowHotKey"
    }
  }

  static var autoCharacterPairs: Bool {
    // Enable it by default
    currentDefinition?.autoCharacterPairs ?? true
  }

  static var indentParagraphs: Bool {
    // Disable it by default
    currentDefinition?.indentParagraphs ?? false
  }

  static var mainWindowHotKey: Definition.HotKey? {
    currentDefinition?.mainWindowHotKey
  }

  static var defaultContents: String {
    let definition = Definition(
      autoCharacterPairs: true,
      indentParagraphs: false,
      mainWindowHotKey: .init(key: "M", modifiers: ["Shift", "Command", "Option"])
    )

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

    guard let jsonData = try? encoder.encode(definition) else {
      Logger.assertFail("Failed to encode object: \(definition)")
      return ""
    }

    return jsonData.toString() ?? ""
  }
}

// MARK: - Private

private extension AppRuntimeConfig {
  static let currentDefinition: Definition? = {
    guard let fileData = AppCustomization.settings.fileData else {
      Logger.assertFail("Missing settings.json to proceed")
      return nil
    }

    guard let definition = try? JSONDecoder().decode(Definition.self, from: fileData) else {
      Logger.assertFail("Invalid json object was found: \(fileData)")
      return nil
    }

    return definition
  }()
}
