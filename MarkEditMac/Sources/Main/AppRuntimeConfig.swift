//
//  AppRuntimeConfig.swift
//  MarkEditMac
//
//  Created by cyan on 8/9/24.
//

import Foundation
@preconcurrency import MarkEditCore
import MarkEditKit

/// Preferences for pro users, not directly visible in the Settings panel.
///
/// The underlying file is stored as "settings.json" in AppCustomization.
enum AppRuntimeConfig {
  struct Definition: Codable, Sendable {
    struct HotKey: Codable {
      let key: String
      let modifiers: [String]
    }

    // swiftlint:disable discouraged_optional_boolean

    let autoCharacterPairs: Bool?
    let closeAlwaysConfirmsChanges: Bool?
    let indentBehavior: EditorIndentBehavior?
    let writingToolsBehavior: String?
    let headerFontSizeDiffs: [Double]?
    let checksForUpdates: Bool?
    let defaultOpenDirectory: String?
    let defaultSaveDirectory: String?
    let disableCorsRestrictions: Bool?
    let mainWindowHotKey: HotKey?

    // swiftlint:enable discouraged_optional_boolean

    enum CodingKeys: String, CodingKey {
      case autoCharacterPairs = "editor.autoCharacterPairs"
      case closeAlwaysConfirmsChanges = "editor.closeAlwaysConfirmsChanges"
      case indentBehavior = "editor.indentBehavior"
      case writingToolsBehavior = "editor.writingToolsBehavior"
      case headerFontSizeDiffs = "editor.headerFontSizeDiffs"
      case checksForUpdates = "general.checksForUpdates"
      case defaultOpenDirectory = "general.defaultOpenDirectory"
      case defaultSaveDirectory = "general.defaultSaveDirectory"
      case disableCorsRestrictions = "general.disableCorsRestrictions"
      case mainWindowHotKey = "general.mainWindowHotKey"
    }
  }

  static var autoCharacterPairs: Bool {
    // Enable auto character pairs by default
    currentDefinition?.autoCharacterPairs ?? true
  }

  // swiftlint:disable:next discouraged_optional_boolean
  static var closeAlwaysConfirmsChanges: Bool? {
    // Changes are saved automatically by default
    currentDefinition?.closeAlwaysConfirmsChanges
  }

  static var indentBehavior: EditorIndentBehavior {
    // No paragraph or line level indentation by default
    currentDefinition?.indentBehavior ?? .never
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

  static var headerFontSizeDiffs: [Double]? {
    // Rely on CoreEditor definitions by default
    currentDefinition?.headerFontSizeDiffs
  }

  static var checksForUpdates: Bool {
    // Enable automatic updates by default
    currentDefinition?.checksForUpdates ?? true
  }

  static var defaultOpenDirectory: String? {
    // Unspecified by default
    currentDefinition?.defaultOpenDirectory
  }

  static var defaultSaveDirectory: String? {
    // Unspecified by default
    currentDefinition?.defaultSaveDirectory
  }

  static var disableCorsRestrictions: Bool {
    // Enforce CORS restrictions by default
    currentDefinition?.disableCorsRestrictions ?? false
  }

  static var mainWindowHotKey: Definition.HotKey? {
    // Shift-Command-Option-M by default
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
    closeAlwaysConfirmsChanges: nil,
    indentBehavior: .never,
    writingToolsBehavior: nil, // [macOS 15] Complete mode still has lots of bugs
    headerFontSizeDiffs: nil,
    checksForUpdates: true,
    defaultOpenDirectory: nil,
    defaultSaveDirectory: nil,
    disableCorsRestrictions: nil,
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
