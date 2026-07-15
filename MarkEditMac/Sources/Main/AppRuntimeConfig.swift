//
//  AppRuntimeConfig.swift
//  MarkEditMac
//
//  Created by cyan on 8/9/24.
//

import AppKit
import SharedUI
import MarkEditCore
import MarkEditKit

/// Preferences for pro users, not directly visible in the Settings panel.
///
/// The underlying file is stored as "settings.json" in AppCustomization.
enum AppRuntimeConfig {
  struct Definition: Codable {
    enum ToolbarTranslucency: Codable {
      case readable
      case `default`
      case vibrant
      case custom(backdropBlur: Double, tintedOpacity: Double, plainOpacity: Double)

      /// Backdrop material: backdropBlur, tintedOpacity, plainOpacity.
      ///
      /// For the presets, readable/default/vibrant step along one "reveal" axis. Tint reads linearly so it
      /// steps arithmetically (default = midpoint); blur reads logarithmically so it steps geometrically
      /// (default = geometric mean, double per step), with tintedOpacity = plainOpacity + 0.3.
      ///
      /// Custom values are used as-is and need not follow these relationships.
      var material: (backdropBlur: Double, tintedOpacity: Double, plainOpacity: Double) {
        switch self {
        case .readable: return (16, 0.9, 0.6)
        case .default: return (8, 0.7, 0.4)
        case .vibrant: return (4, 0.5, 0.2)
        case let .custom(backdropBlur, tintedOpacity, plainOpacity):
          return (backdropBlur, tintedOpacity, plainOpacity)
        }
      }

      init(from decoder: any Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        switch value {
        case "readable": self = .readable
        case "default": self = .default
        case "vibrant": self = .vibrant
        default:
          // Accept a custom "blur, tinted, plain" string, e.g. "8, 0.7, 0.4"
          let numbers = value.split(separator: ",").compactMap {
            Double($0.trimmingCharacters(in: .whitespaces))
          }

          guard numbers.count == 3 else {
            Logger.log(.error, "Invalid toolbarTranslucency value: \(value)")
            self = .default
            return
          }

          self = .custom(backdropBlur: numbers[0], tintedOpacity: numbers[1], plainOpacity: numbers[2])
        }
      }

      func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .readable: try container.encode("readable")
        case .default: try container.encode("default")
        case .vibrant: try container.encode("vibrant")
        case let .custom(backdropBlur, tintedOpacity, plainOpacity):
          try container.encode("\(backdropBlur), \(tintedOpacity), \(plainOpacity)")
        }
      }
    }

    enum UpdateBehavior: String, Codable {
      case quiet = "quiet"
      case notify = "notify"
      case never = "never"
    }

    struct HotKey: Codable {
      let key: String
      let modifiers: [String]
    }

    let __schema: String?
    let autoCharacterPairs: Bool?
    let autoSaveWhenIdle: Bool?
    let closeAlwaysConfirmsChanges: Bool?
    let restoreLastSelection: Bool?
    let indentBehavior: EditorIndentBehavior?
    let writingToolsBehavior: String?
    let headerFontSizeDiffs: [Double]?
    let visibleWhitespaceCharacter: String?
    let visibleLineBreakCharacter: String?
    let searchNormalizers: [String: String]?
    let nativeSearchQuerySync: Bool?
    let toolbarTranslucency: ToolbarTranslucency?
    let customToolbarItems: [CustomToolbarItem]?
    let updateBehavior: UpdateBehavior?
    let checksForUpdates: Bool? // [Deprecated] Kept for backward compatibility
    let defaultOpenDirectory: String?
    let defaultSaveDirectory: String?
    let disableOpenPanelOptions: Bool?
    let disableCorsRestrictions: Bool?
    let disabledWebKitFeatures: [String]?
    let preferredTerminalApp: String?
    let mainWindowHotKey: HotKey?

    enum CodingKeys: String, CodingKey {
      case __schema = "$schema"
      case autoCharacterPairs = "editor.autoCharacterPairs"
      case autoSaveWhenIdle = "editor.autoSaveWhenIdle"
      case closeAlwaysConfirmsChanges = "editor.closeAlwaysConfirmsChanges"
      case restoreLastSelection = "editor.restoreLastSelection"
      case indentBehavior = "editor.indentBehavior"
      case writingToolsBehavior = "editor.writingToolsBehavior"
      case headerFontSizeDiffs = "editor.headerFontSizeDiffs"
      case visibleWhitespaceCharacter = "editor.visibleWhitespaceCharacter"
      case visibleLineBreakCharacter = "editor.visibleLineBreakCharacter"
      case searchNormalizers = "editor.searchNormalizers"
      case nativeSearchQuerySync = "editor.nativeSearchQuerySync"
      case toolbarTranslucency = "editor.toolbarTranslucency"
      case customToolbarItems = "editor.customToolbarItems"
      case updateBehavior = "general.updateBehavior"
      case checksForUpdates = "general.checksForUpdates"
      case defaultOpenDirectory = "general.defaultOpenDirectory"
      case defaultSaveDirectory = "general.defaultSaveDirectory"
      case disableOpenPanelOptions = "general.disableOpenPanelOptions"
      case disableCorsRestrictions = "general.disableCorsRestrictions"
      case disabledWebKitFeatures = "general.disabledWebKitFeatures"
      case preferredTerminalApp = "general.preferredTerminalApp"
      case mainWindowHotKey = "general.mainWindowHotKey"
    }
  }

  static let jsonLiteral: String = {
    {
      guard let fileData, (try? JSONSerialization.jsonObject(with: fileData, options: [])) != nil else {
        Logger.log(.error, "Invalid json file was found at: \(AppCustomization.settings.fileURL)")
        return nil
      }

      return fileData.toString()
    }() ?? "{}"
  }()

  static var jsonObject: [String: Any] {
    guard let data = fileData, let object = try? JSONSerialization.jsonObject(with: data) else {
      return [:]
    }

    return (object as? [String: Any]) ?? [:]
  }

  static var restoreLastSelection: Bool {
    // Restore selection from previous session by default
    currentDefinition?.restoreLastSelection ?? true
  }

  static var autoCharacterPairs: Bool {
    // Enable auto character pairs by default
    currentDefinition?.autoCharacterPairs ?? true
  }

  static var autoSaveWhenIdle: Bool {
    if closeAlwaysConfirmsChanges == true {
      // If changes require confirmation, they are not saved periodically
      return false
    }

    return currentDefinition?.autoSaveWhenIdle ?? false
  }

  static var closeAlwaysConfirmsChanges: Bool? {
    // Changes are saved automatically by default
    currentDefinition?.closeAlwaysConfirmsChanges
  }

  static var indentBehavior: EditorIndentBehavior {
    // No paragraph or line level indentation by default
    currentDefinition?.indentBehavior ?? .never
  }

  static var writingToolsBehavior: NSWritingToolsBehavior? {
    switch currentDefinition?.writingToolsBehavior {
    case "none": return NSWritingToolsBehavior.none
    case "complete": return NSWritingToolsBehavior.complete
    case "limited": return NSWritingToolsBehavior.limited
    default: return nil
    }
  }

  static var headerFontSizeDiffs: [Double]? {
    // Rely on CoreEditor definitions by default
    currentDefinition?.headerFontSizeDiffs
  }

  static var visibleWhitespaceCharacter: String? {
    currentDefinition?.visibleWhitespaceCharacter
  }

  static var visibleLineBreakCharacter: String? {
    currentDefinition?.visibleLineBreakCharacter
  }

  static var searchNormalizers: [String: String]? {
    currentDefinition?.searchNormalizers
  }

  static var nativeSearchQuerySync: Bool {
    currentDefinition?.nativeSearchQuerySync ?? false
  }

  static var toolbarTranslucency: Definition.ToolbarTranslucency {
    currentDefinition?.toolbarTranslucency ?? .default
  }

  static var customToolbarItems: [CustomToolbarItem] {
    currentDefinition?.customToolbarItems ?? []
  }

  static var updateBehavior: Definition.UpdateBehavior {
    guard currentDefinition?.checksForUpdates ?? true else {
      return .never
    }

    return currentDefinition?.updateBehavior ?? .quiet
  }

  static var defaultOpenDirectory: String? {
    // Unspecified by default
    currentDefinition?.defaultOpenDirectory
  }

  static var defaultSaveDirectory: String? {
    // Unspecified by default
    currentDefinition?.defaultSaveDirectory
  }

  static var disableOpenPanelOptions: Bool {
    currentDefinition?.disableOpenPanelOptions ?? ({
      // [macOS 26] Revisit this later,
      // NSOpenPanel.accessoryView can significantly slow down the file opening process.
      if #available(macOS 26.0, *) {
        return true
      }

      return false
    })()
  }

  static var disableCorsRestrictions: Bool {
    // CORS restrictions are disabled by default; we're a local editor, not a browser
    currentDefinition?.disableCorsRestrictions ?? true
  }

  static var disabledWebKitFeatures: [String] {
    // No extra WKPreferences feature flags disabled by default
    currentDefinition?.disabledWebKitFeatures ?? []
  }

  static var preferredTerminalApp: String? {
    // Use auto-detection by default
    currentDefinition?.preferredTerminalApp
  }

  static var mainWindowHotKey: Definition.HotKey? {
    // Shift-Command-Option-M by default
    currentDefinition?.mainWindowHotKey
  }

  static var defaultContents: String {
    encode(definition: defaultDefinition)?.toString() ?? ""
  }
}

struct CustomToolbarItem: Codable {
  let title: String
  let icon: String
  let actionName: String?
  let menuName: String?

  var identifier: NSToolbarItem.Identifier {
    let components = [
      title,
      icon,
      actionName,
      menuName,
    ].compactMap { $0 }.joined(separator: "-")

    let prefix = "app.markedit.custom"
    return NSToolbarItem.Identifier(rawValue: "\(prefix).\(components.sha256Hash)")
  }
}

// MARK: - Private

private extension AppRuntimeConfig {
  /**
   The raw JSON data of the settings.json file.
   */
  static let fileData = try? Data(contentsOf: AppCustomization.settings.fileURL)

  static let defaultDefinition = Definition(
    __schema: "https://raw.githubusercontent.com/MarkEdit-app/schemas/main/settings.json",
    autoCharacterPairs: true,
    autoSaveWhenIdle: false,
    closeAlwaysConfirmsChanges: nil,
    restoreLastSelection: nil,
    indentBehavior: .never,
    writingToolsBehavior: nil, // [macOS 15] Complete mode still has lots of bugs
    headerFontSizeDiffs: nil,
    visibleWhitespaceCharacter: nil,
    visibleLineBreakCharacter: nil,
    searchNormalizers: nil,
    nativeSearchQuerySync: false,
    toolbarTranslucency: nil, // Keeping nil allows us to tweak defaults later
    customToolbarItems: [],
    updateBehavior: .quiet,
    checksForUpdates: nil,
    defaultOpenDirectory: nil,
    defaultSaveDirectory: nil,
    disableOpenPanelOptions: nil, // [macOS 26] Future macOS with the fix can be opted out
    disableCorsRestrictions: true,
    disabledWebKitFeatures: nil,
    preferredTerminalApp: nil,
    mainWindowHotKey: .init(key: "M", modifiers: ["Shift", "Command", "Option"])
  )

  static let currentDefinition: Definition? = {
    guard let fileData else {
      Logger.log(.error, "Missing settings.json to proceed")
      return nil
    }

    guard let definition = try? JSONDecoder().decode(Definition.self, from: fileData) else {
      Logger.log(.error, "Invalid json object was found: \(fileData)")
      return nil
    }

    return definition
  }()

  static func encode(definition: Definition) -> Data? {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

    let jsonData = try? encoder.encode(definition)
    Logger.assert(jsonData != nil, "Failed to encode object: \(definition)")

    return jsonData
  }
}
