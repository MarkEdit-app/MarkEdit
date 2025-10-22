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
  func getFileInfo() async -> String?
  func getPasteboardItems() async -> String?
  func getPasteboardString() async -> String?
  func addMainMenuItems(items: [WebMenuItem])
  func showContextMenu(items: [WebMenuItem], location: WebPoint)
  func showAlert(title: String?, message: String?, buttons: [String]?) async -> Int
  func showTextBox(title: String?, placeholder: String?, defaultValue: String?) async -> String?
  func showSavePanel(options: SavePanelOptions) async -> Bool
  func runService(name: String, input: String?) async -> Bool
}

public extension NativeModuleAPI {
  var bridge: NativeBridge { NativeBridgeAPI(self) }
}

@MainActor
final class NativeBridgeAPI: NativeBridge {
  static let name = "api"
  lazy var methods: [String: NativeMethod] = [
    "getFileInfo": { [weak self] in
      await self?.getFileInfo(parameters: $0)
    },
    "getPasteboardItems": { [weak self] in
      await self?.getPasteboardItems(parameters: $0)
    },
    "getPasteboardString": { [weak self] in
      await self?.getPasteboardString(parameters: $0)
    },
    "addMainMenuItems": { [weak self] in
      await self?.addMainMenuItems(parameters: $0)
    },
    "showContextMenu": { [weak self] in
      await self?.showContextMenu(parameters: $0)
    },
    "showAlert": { [weak self] in
      await self?.showAlert(parameters: $0)
    },
    "showTextBox": { [weak self] in
      await self?.showTextBox(parameters: $0)
    },
    "showSavePanel": { [weak self] in
      await self?.showSavePanel(parameters: $0)
    },
    "runService": { [weak self] in
      await self?.runService(parameters: $0)
    },
  ]

  private let module: NativeModuleAPI
  private lazy var decoder = JSONDecoder()

  init(_ module: NativeModuleAPI) {
    self.module = module
  }

  private func getFileInfo(parameters: Data) async -> Result<Any?, Error>? {
    let result = await module.getFileInfo()
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

  private func addMainMenuItems(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var items: [WebMenuItem]
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
}

/// Represents a menu item in native menus.
public struct WebMenuItem: Decodable, Equatable {
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
}

/// "CGPoint-fashion" point.
public struct WebPoint: Decodable, Equatable {
  public var x: Double
  public var y: Double

  public init(x: Double, y: Double) {
    self.x = x
    self.y = y
  }
}

public struct SavePanelOptions: Decodable, Equatable {
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
}
