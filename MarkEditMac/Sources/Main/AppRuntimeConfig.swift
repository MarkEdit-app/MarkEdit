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
    let writingToolsBehavior: String?
    let mainWindowHotKey: HotKey?

    // swiftlint:enable discouraged_optional_boolean

    enum CodingKeys: String, CodingKey {
      case autoCharacterPairs = "editor.autoCharacterPairs"
      case indentParagraphs = "editor.indentParagraphs"
      case writingToolsBehavior = "editor.writingToolsBehavior"
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

  // [macOS 15] Move to public API when it's ready
  static var writingToolsBehavior: Int? {
    /// https://developer.apple.com/documentation/webkit/wkwebviewconfiguration/4459101-writingtoolsbehavior
    switch currentDefinition?.writingToolsBehavior {
    case "none": return -1
    case "complete": return 1
    case "limited": return 2
    default: return nil
    }
  }

  static var mainWindowHotKey: Definition.HotKey? {
    currentDefinition?.mainWindowHotKey
  }

  static var defaultContents: String {
    encode(definition: defaultDefinition)?.toString() ?? ""
  }
}

// MARK: - Private

private extension AppRuntimeConfig {
  static let defaultDefinition = Definition(
    autoCharacterPairs: true,
    indentParagraphs: false,
    writingToolsBehavior: nil, // [macOS 15] Complete mode still has lots of bugs
    mainWindowHotKey: .init(key: "M", modifiers: ["Shift", "Command", "Option"])
  )

  static let currentDefinition: Definition? = {
    guard let fileData = try? Data(contentsOf: AppCustomization.settings.fileURL) else {
      Logger.assertFail("Missing settings.json to proceed")
      return nil
    }

    guard let definition = try? JSONDecoder().decode(Definition.self, from: fileData) else {
      Logger.assertFail("Invalid json object was found: \(fileData)")
      return nil
    }

    return definition
  }()

  static func encode(definition: Definition) -> Data? {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

    let jsonData = try? encoder.encode(definition)
    Logger.assert(jsonData != nil, "Failed to encode object: \(definition)")

    return jsonData
  }
}
