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
  func saveDocument() async -> Bool
  func closeDocument() async -> Bool
  func addMainMenuItems(items: [WebMenuItem])
  func showContextMenu(items: [WebMenuItem], location: WebPoint)
  func showAlert(title: String?, message: String?, buttons: [String]?) async -> Int
  func showTextBox(title: String?, placeholder: String?, defaultValue: String?) async -> String?
  func showSavePanel(options: SavePanelOptions) async -> Bool
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
  func getPasteboardItems() async -> String?
  func getPasteboardString() async -> String?
  func terminateApp()
  func relaunchApp()
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
    case "saveDocument":
      return await saveDocument(parameters: parameters)
    case "closeDocument":
      return await closeDocument(parameters: parameters)
    case "addMainMenuItems":
      return await addMainMenuItems(parameters: parameters)
    case "showContextMenu":
      return await showContextMenu(parameters: parameters)
    case "showAlert":
      return await showAlert(parameters: parameters)
    case "showTextBox":
      return await showTextBox(parameters: parameters)
    case "showSavePanel":
      return await showSavePanel(parameters: parameters)
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
    case "getPasteboardItems":
      return await getPasteboardItems(parameters: parameters)
    case "getPasteboardString":
      return await getPasteboardString(parameters: parameters)
    case "terminateApp":
      return await terminateApp(parameters: parameters)
    case "relaunchApp":
      return await relaunchApp(parameters: parameters)
    default:
      return nil
    }
  }

  private func saveDocument(parameters: Data) async -> Result<Any?, Error>? {
    let result = await module.saveDocument()
    return .success(result)
  }

  private func closeDocument(parameters: Data) async -> Result<Any?, Error>? {
    let result = await module.closeDocument()
    return .success(result)
  }

  private func addMainMenuItems(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var items: [WebMenuItem]

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        items = try container.value("items")
      }
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    module.addMainMenuItems(items: message.items)
    return .success(nil)
  }

  private func showContextMenu(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var items: [WebMenuItem]
      var location: WebPoint

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        items = try container.value("items")
        location = try container.value("location")
      }
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    module.showContextMenu(items: message.items, location: message.location)
    return .success(nil)
  }

  private func showAlert(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var title: String?
      var message: String?
      var buttons: [String]?

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        title = try container.value("title")
        message = try container.value("message")
        buttons = try container.value("buttons")
      }
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.showAlert(title: message.title, message: message.message, buttons: message.buttons)
    return .success(result)
  }

  private func showTextBox(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var title: String?
      var placeholder: String?
      var defaultValue: String?

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        title = try container.value("title")
        placeholder = try container.value("placeholder")
        defaultValue = try container.value("defaultValue")
      }
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.showTextBox(title: message.title, placeholder: message.placeholder, defaultValue: message.defaultValue)
    return .success(result)
  }

  private func showSavePanel(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var options: SavePanelOptions

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        options = try container.value("options")
      }
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.showSavePanel(options: message.options)
    return .success(result)
  }

  private func runService(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var name: String
      var input: String?

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        name = try container.value("name")
        input = try container.value("input")
      }
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.runService(name: message.name, input: message.input)
    return .success(result)
  }

  private func openFile(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var path: String

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        path = try container.value("path")
      }
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.openFile(path: message.path)
    return .success(result)
  }

  private func createFile(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var options: CreateFileOptions

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        options = try container.value("options")
      }
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.createFile(options: message.options)
    return .success(result)
  }

  private func deleteFile(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var path: String

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        path = try container.value("path")
      }
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.deleteFile(path: message.path)
    return .success(result)
  }

  private func moveFile(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var options: MoveFileOptions

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        options = try container.value("options")
      }
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.moveFile(options: message.options)
    return .success(result)
  }

  private func revealFile(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var path: String?

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        path = try container.value("path")
      }
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.revealFile(path: message.path)
    return .success(result)
  }

  private func listFiles(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var path: String

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        path = try container.value("path")
      }
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.listFiles(path: message.path)
    return .success(result)
  }

  private func getFileContent(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var path: String?

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        path = try container.value("path")
      }
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.getFileContent(path: message.path)
    return .success(result)
  }

  private func getFileObject(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var path: String?

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        path = try container.value("path")
      }
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.getFileObject(path: message.path)
    return .success(result)
  }

  private func getFileInfo(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var path: String?

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        path = try container.value("path")
      }
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.getFileInfo(path: message.path)
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

  private func terminateApp(parameters: Data) async -> Result<Any?, Error>? {
    module.terminateApp()
    return .success(nil)
  }

  private func relaunchApp(parameters: Data) async -> Result<Any?, Error>? {
    module.relaunchApp()
    return .success(nil)
  }
}

/// Represents a menu item in native menus.
public struct WebMenuItem: Decodable {
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
public struct WebPoint: Decodable {
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

public struct SavePanelOptions: Decodable {
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

public struct CreateFileOptions: Decodable {
  /// File path.
  ///
  /// It must be one that the app can access. See the [wiki](https://github.com/MarkEdit-app/MarkEdit/wiki/Customization#grant-folder-access) for more details.
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

public struct MoveFileOptions: Decodable {
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
