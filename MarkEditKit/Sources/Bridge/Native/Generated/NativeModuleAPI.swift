//
//  NativeModuleAPI.swift
//
//  Generated using https://github.com/microsoft/ts-gyb
//
//  Don't modify this file manually, it's auto generated.
//
//  To make changes, edit template files under /CoreEditor/src/@codegen

import Foundation
import MarkEditCore

@MainActor
public protocol NativeModuleAPI: NativeModule {
  func openDocument(path: String, target: NativeModuleAPIOpenDocumentTarget?) async -> Bool
  func saveDocument() async -> Bool
  func closeDocument() async -> Bool
  func recentDocumentPaths() async -> [String]
  func addMainMenuItems(items: [WebMenuItem])
  func showContextMenu(items: [WebMenuItem], location: WebPoint, highlightedIndex: Int?)
  func showAlert(title: String?, message: String?, buttons: [String]?) async -> Int
  func showTextBox(title: String?, placeholder: String?, defaultValue: String?) async -> String?
  func showOpenPanel(options: OpenPanelOptions) async -> [String]?
  func showSavePanel(options: SavePanelOptions) async -> Bool
  func showPrintPanel(options: PrintPanelOptions) async -> Bool
  func runService(name: String, input: String?) async -> Bool
  func openFile(path: String) async -> Bool
  func createFile(options: CreateFileOptions) async -> Bool
  func deleteFile(path: String) async -> Bool
  func moveFile(options: MoveFileOptions) async -> Bool
  func revealFile(path: String?) async -> Bool
  func listFiles(path: String) async -> [String]?
  func getFileContent(path: String?) async -> String?
  func getFileObject(path: String?) async -> String?
  func getFileInfo(path: String?) async -> String?
  func getFileVersions() async -> String?
  func getFileVersionContent(id: String) async -> String?
  func restoreFileVersion(id: String) async -> Bool
  func deleteLocalFileVersions(ids: [String]) async -> Bool
  func getPasteboardItems() async -> String?
  func getPasteboardString() async -> String?
  func terminateApp()
  func relaunchApp()
  func playSystemBeep()
}

public extension NativeModuleAPI {
  var bridge: NativeBridge { NativeBridgeAPI(self) }
}

@MainActor
final class NativeBridgeAPI: NativeBridge {
  static let name = "api"

  private let module: NativeModuleAPI
  private lazy var decoder = JSONDecoder()

  init(_ module: NativeModuleAPI) {
    self.module = module
  }

  func invoke(method: String, parameters: Data) async -> Result<Any?, Error>? {
    switch method {
    case "openDocument":
      return await openDocument(parameters: parameters)
    case "saveDocument":
      return await saveDocument(parameters: parameters)
    case "closeDocument":
      return await closeDocument(parameters: parameters)
    case "recentDocumentPaths":
      return await recentDocumentPaths(parameters: parameters)
    case "addMainMenuItems":
      return addMainMenuItems(parameters: parameters)
    case "showContextMenu":
      return showContextMenu(parameters: parameters)
    case "showAlert":
      return await showAlert(parameters: parameters)
    case "showTextBox":
      return await showTextBox(parameters: parameters)
    case "showOpenPanel":
      return await showOpenPanel(parameters: parameters)
    case "showSavePanel":
      return await showSavePanel(parameters: parameters)
    case "showPrintPanel":
      return await showPrintPanel(parameters: parameters)
    case "runService":
      return await runService(parameters: parameters)
    case "openFile":
      return await openFile(parameters: parameters)
    case "createFile":
      return await createFile(parameters: parameters)
    case "deleteFile":
      return await deleteFile(parameters: parameters)
    case "moveFile":
      return await moveFile(parameters: parameters)
    case "revealFile":
      return await revealFile(parameters: parameters)
    case "listFiles":
      return await listFiles(parameters: parameters)
    case "getFileContent":
      return await getFileContent(parameters: parameters)
    case "getFileObject":
      return await getFileObject(parameters: parameters)
    case "getFileInfo":
      return await getFileInfo(parameters: parameters)
    case "getFileVersions":
      return await getFileVersions(parameters: parameters)
    case "getFileVersionContent":
      return await getFileVersionContent(parameters: parameters)
    case "restoreFileVersion":
      return await restoreFileVersion(parameters: parameters)
    case "deleteLocalFileVersions":
      return await deleteLocalFileVersions(parameters: parameters)
    case "getPasteboardItems":
      return await getPasteboardItems(parameters: parameters)
    case "getPasteboardString":
      return await getPasteboardString(parameters: parameters)
    case "terminateApp":
      return terminateApp(parameters: parameters)
    case "relaunchApp":
      return relaunchApp(parameters: parameters)
    case "playSystemBeep":
      return playSystemBeep(parameters: parameters)
    default:
      return nil
    }
  }

  private func openDocument(parameters: Data) async -> Result<Any?, Error>? {
    let parameter_path: String
    let parameter_target: NativeModuleAPIOpenDocumentTarget?

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_path = try container.value("path")
      parameter_target = try container.value("target")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.openDocument(path: parameter_path, target: parameter_target)
    return .success(result)
  }

  private func saveDocument(parameters: Data) async -> Result<Any?, Error>? {
    let result = await module.saveDocument()
    return .success(result)
  }

  private func closeDocument(parameters: Data) async -> Result<Any?, Error>? {
    let result = await module.closeDocument()
    return .success(result)
  }

  private func recentDocumentPaths(parameters: Data) async -> Result<Any?, Error>? {
    let result = await module.recentDocumentPaths()
    return .success(result)
  }

  private func addMainMenuItems(parameters: Data) -> Result<Any?, Error>? {
    let parameter_items: [WebMenuItem]

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_items = try container.value("items")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    module.addMainMenuItems(items: parameter_items)
    return .success(nil)
  }

  private func showContextMenu(parameters: Data) -> Result<Any?, Error>? {
    let parameter_items: [WebMenuItem]
    let parameter_location: WebPoint
    let parameter_highlightedIndex: Int?

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_items = try container.value("items")
      parameter_location = try container.value("location")
      parameter_highlightedIndex = try container.value("highlightedIndex")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    module.showContextMenu(items: parameter_items, location: parameter_location, highlightedIndex: parameter_highlightedIndex)
    return .success(nil)
  }

  private func showAlert(parameters: Data) async -> Result<Any?, Error>? {
    let parameter_title: String?
    let parameter_message: String?
    let parameter_buttons: [String]?

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_title = try container.value("title")
      parameter_message = try container.value("message")
      parameter_buttons = try container.value("buttons")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.showAlert(title: parameter_title, message: parameter_message, buttons: parameter_buttons)
    return .success(result)
  }

  private func showTextBox(parameters: Data) async -> Result<Any?, Error>? {
    let parameter_title: String?
    let parameter_placeholder: String?
    let parameter_defaultValue: String?

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_title = try container.value("title")
      parameter_placeholder = try container.value("placeholder")
      parameter_defaultValue = try container.value("defaultValue")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.showTextBox(title: parameter_title, placeholder: parameter_placeholder, defaultValue: parameter_defaultValue)
    return .success(result)
  }

  private func showOpenPanel(parameters: Data) async -> Result<Any?, Error>? {
    let parameter_options: OpenPanelOptions

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_options = try container.value("options")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.showOpenPanel(options: parameter_options)
    return .success(result)
  }

  private func showSavePanel(parameters: Data) async -> Result<Any?, Error>? {
    let parameter_options: SavePanelOptions

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_options = try container.value("options")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.showSavePanel(options: parameter_options)
    return .success(result)
  }

  private func showPrintPanel(parameters: Data) async -> Result<Any?, Error>? {
    let parameter_options: PrintPanelOptions

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_options = try container.value("options")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.showPrintPanel(options: parameter_options)
    return .success(result)
  }

  private func runService(parameters: Data) async -> Result<Any?, Error>? {
    let parameter_name: String
    let parameter_input: String?

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_name = try container.value("name")
      parameter_input = try container.value("input")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.runService(name: parameter_name, input: parameter_input)
    return .success(result)
  }

  private func openFile(parameters: Data) async -> Result<Any?, Error>? {
    let parameter_path: String

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_path = try container.value("path")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.openFile(path: parameter_path)
    return .success(result)
  }

  private func createFile(parameters: Data) async -> Result<Any?, Error>? {
    let parameter_options: CreateFileOptions

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_options = try container.value("options")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.createFile(options: parameter_options)
    return .success(result)
  }

  private func deleteFile(parameters: Data) async -> Result<Any?, Error>? {
    let parameter_path: String

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_path = try container.value("path")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.deleteFile(path: parameter_path)
    return .success(result)
  }

  private func moveFile(parameters: Data) async -> Result<Any?, Error>? {
    let parameter_options: MoveFileOptions

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_options = try container.value("options")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.moveFile(options: parameter_options)
    return .success(result)
  }

  private func revealFile(parameters: Data) async -> Result<Any?, Error>? {
    let parameter_path: String?

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_path = try container.value("path")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.revealFile(path: parameter_path)
    return .success(result)
  }

  private func listFiles(parameters: Data) async -> Result<Any?, Error>? {
    let parameter_path: String

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_path = try container.value("path")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.listFiles(path: parameter_path)
    return .success(result)
  }

  private func getFileContent(parameters: Data) async -> Result<Any?, Error>? {
    let parameter_path: String?

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_path = try container.value("path")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.getFileContent(path: parameter_path)
    return .success(result)
  }

  private func getFileObject(parameters: Data) async -> Result<Any?, Error>? {
    let parameter_path: String?

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_path = try container.value("path")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.getFileObject(path: parameter_path)
    return .success(result)
  }

  private func getFileInfo(parameters: Data) async -> Result<Any?, Error>? {
    let parameter_path: String?

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_path = try container.value("path")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.getFileInfo(path: parameter_path)
    return .success(result)
  }

  private func getFileVersions(parameters: Data) async -> Result<Any?, Error>? {
    let result = await module.getFileVersions()
    return .success(result)
  }

  private func getFileVersionContent(parameters: Data) async -> Result<Any?, Error>? {
    let parameter_id: String

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_id = try container.value("id")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.getFileVersionContent(id: parameter_id)
    return .success(result)
  }

  private func restoreFileVersion(parameters: Data) async -> Result<Any?, Error>? {
    let parameter_id: String

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_id = try container.value("id")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.restoreFileVersion(id: parameter_id)
    return .success(result)
  }

  private func deleteLocalFileVersions(parameters: Data) async -> Result<Any?, Error>? {
    let parameter_ids: [String]

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_ids = try container.value("ids")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.deleteLocalFileVersions(ids: parameter_ids)
    return .success(result)
  }

  private func getPasteboardItems(parameters: Data) async -> Result<Any?, Error>? {
    let result = await module.getPasteboardItems()
    return .success(result)
  }

  private func getPasteboardString(parameters: Data) async -> Result<Any?, Error>? {
    let result = await module.getPasteboardString()
    return .success(result)
  }

  private func terminateApp(parameters: Data) -> Result<Any?, Error>? {
    module.terminateApp()
    return .success(nil)
  }

  private func relaunchApp(parameters: Data) -> Result<Any?, Error>? {
    module.relaunchApp()
    return .success(nil)
  }

  private func playSystemBeep(parameters: Data) -> Result<Any?, Error>? {
    module.playSystemBeep()
    return .success(nil)
  }
}

public enum NativeModuleAPIOpenDocumentTarget: String, Codable, Sendable {
  case automatic = "automatic"
  case window = "window"
  case tab = "tab"
}

/// Represents a menu item in native menus.
public struct WebMenuItem: Decodable, Sendable {
  public var separator: Bool
  public var title: String?
  public var icon: String?
  public var actionID: String?
  public var stateGetterID: String?
  public var key: String?
  public var modifiers: [String]?
  public var children: [Self]?

  public init(separator: Bool, title: String?, icon: String?, actionID: String?, stateGetterID: String?, key: String?, modifiers: [String]?, children: [Self]?) {
    self.separator = separator
    self.title = title
    self.icon = icon
    self.actionID = actionID
    self.stateGetterID = stateGetterID
    self.key = key
    self.modifiers = modifiers
    self.children = children
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: BridgeFieldKey.self)
    separator = try container.value("separator")
    title = try container.value("title")
    icon = try container.value("icon")
    actionID = try container.value("actionID")
    stateGetterID = try container.value("stateGetterID")
    key = try container.value("key")
    modifiers = try container.value("modifiers")
    children = try container.value("children")
  }
}

/// "CGPoint-fashion" point.
public struct WebPoint: Decodable, Sendable {
  public var x: Double
  public var y: Double

  public init(x: Double, y: Double) {
    self.x = x
    self.y = y
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: BridgeFieldKey.self)
    x = try container.value("x")
    y = try container.value("y")
  }
}

public struct OpenPanelOptions: Decodable, Sendable {
  /// Panel title. Uses the system default if omitted.
  public var title: String?
  /// Instructions displayed in the panel.
  public var message: String?
  /// Confirmation button label. Uses the system default if omitted.
  public var prompt: String?
  /// Types of items that can be selected. Defaults to 'files'.
  public var selectionType: OpenPanelOptionsMembersSelectionTypeType?
  /// Allow selecting multiple items. Defaults to false.
  public var allowsMultipleSelection: Bool?

  public init(title: String?, message: String?, prompt: String?, selectionType: OpenPanelOptionsMembersSelectionTypeType?, allowsMultipleSelection: Bool?) {
    self.title = title
    self.message = message
    self.prompt = prompt
    self.selectionType = selectionType
    self.allowsMultipleSelection = allowsMultipleSelection
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: BridgeFieldKey.self)
    title = try container.value("title")
    message = try container.value("message")
    prompt = try container.value("prompt")
    selectionType = try container.value("selectionType")
    allowsMultipleSelection = try container.value("allowsMultipleSelection")
  }
}

public enum OpenPanelOptionsMembersSelectionTypeType: String, Codable, Sendable {
  case files = "files"
  case directories = "directories"
  case both = "both"
}

public struct SavePanelOptions: Decodable, Sendable {
  /// String representation of the file, if applicable.
  public var string: String?
  /// Base64 representation of the file, if applicable.
  public var data: String?
  /// Default file name.
  public var fileName: String?

  public init(string: String?, data: String?, fileName: String?) {
    self.string = string
    self.data = data
    self.fileName = fileName
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: BridgeFieldKey.self)
    string = try container.value("string")
    data = try container.value("data")
    fileName = try container.value("fileName")
  }
}

public struct PrintPanelOptions: Decodable, Sendable {
  /// Base64 representation of the content to print. For 'pdf', this is PDF data.
  public var data: String
  /// Job title shown in the print panel and print queue.
  public var title: String?
  /// Content type to print. Currently only PDF is supported.
  private var type: String = "pdf"

  public init(data: String, title: String?) {
    self.data = data
    self.title = title
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: BridgeFieldKey.self)
    data = try container.value("data")
    title = try container.value("title")
    type = try container.value("type")
  }
}

public struct CreateFileOptions: Decodable, Sendable {
  /// File path.
  public var path: String
  /// If set to true, a directory will be created instead.
  public var isDirectory: Bool?
  /// If set to true, existing files with the same path will be overwritten.
  public var overwrites: Bool?
  /// String representation of the file, if applicable.
  public var string: String?
  /// Base64 representation of the file, if applicable.
  public var data: String?

  public init(path: String, isDirectory: Bool?, overwrites: Bool?, string: String?, data: String?) {
    self.path = path
    self.isDirectory = isDirectory
    self.overwrites = overwrites
    self.string = string
    self.data = data
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: BridgeFieldKey.self)
    path = try container.value("path")
    isDirectory = try container.value("isDirectory")
    overwrites = try container.value("overwrites")
    string = try container.value("string")
    data = try container.value("data")
  }
}

public struct MoveFileOptions: Decodable, Sendable {
  /// Source file path.
  public var source: String
  /// Destination file path.
  public var destination: String
  /// If set to true, existing files at the destination will be overwritten.
  public var overwrites: Bool?

  public init(source: String, destination: String, overwrites: Bool?) {
    self.source = source
    self.destination = destination
    self.overwrites = overwrites
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: BridgeFieldKey.self)
    source = try container.value("source")
    destination = try container.value("destination")
    overwrites = try container.value("overwrites")
  }
}
