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
  func getFileInfo() -> String?
  func getPasteboardItems() -> String?
  func getPasteboardString() -> String?
  func addMainMenuItems(items: [WebMenuItem])
  func showContextMenu(items: [WebMenuItem], location: WebPoint)
  func showAlert(title: String?, message: String?, buttons: [String]?) -> Int
  func showTextBox(title: String?, placeholder: String?, defaultValue: String?) -> String?
  func showSavePanel(options: SavePanelOptions) -> Bool
}

public extension NativeModuleAPI {
  var bridge: NativeBridge { NativeBridgeAPI(self) }
}

@MainActor
final class NativeBridgeAPI: NativeBridge {
  static let name = "api"
  lazy var methods: [String: NativeMethod] = [
    "getFileInfo": { [weak self] in
      self?.getFileInfo(parameters: $0)
    },
    "getPasteboardItems": { [weak self] in
      self?.getPasteboardItems(parameters: $0)
    },
    "getPasteboardString": { [weak self] in
      self?.getPasteboardString(parameters: $0)
    },
    "addMainMenuItems": { [weak self] in
      self?.addMainMenuItems(parameters: $0)
    },
    "showContextMenu": { [weak self] in
      self?.showContextMenu(parameters: $0)
    },
    "showAlert": { [weak self] in
      self?.showAlert(parameters: $0)
    },
    "showTextBox": { [weak self] in
      self?.showTextBox(parameters: $0)
    },
    "showSavePanel": { [weak self] in
      self?.showSavePanel(parameters: $0)
    },
  ]

  private let module: NativeModuleAPI
  private lazy var decoder = JSONDecoder()

  init(_ module: NativeModuleAPI) {
    self.module = module
  }

  private func getFileInfo(parameters: Data) -> Result<Any?, Error>? {
    let result = module.getFileInfo()
    return .success(result)
  }

  private func getPasteboardItems(parameters: Data) -> Result<Any?, Error>? {
    let result = module.getPasteboardItems()
    return .success(result)
  }

  private func getPasteboardString(parameters: Data) -> Result<Any?, Error>? {
    let result = module.getPasteboardString()
    return .success(result)
  }

  private func addMainMenuItems(parameters: Data) -> Result<Any?, Error>? {
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

  private func showContextMenu(parameters: Data) -> Result<Any?, Error>? {
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

  private func showAlert(parameters: Data) -> Result<Any?, Error>? {
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

    let result = module.showAlert(title: message.title, message: message.message, buttons: message.buttons)
    return .success(result)
  }

  private func showTextBox(parameters: Data) -> Result<Any?, Error>? {
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

    let result = module.showTextBox(title: message.title, placeholder: message.placeholder, defaultValue: message.defaultValue)
    return .success(result)
  }

  private func showSavePanel(parameters: Data) -> Result<Any?, Error>? {
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

    let result = module.showSavePanel(options: message.options)
    return .success(result)
  }
}

/// Represents a menu item in native menus.
public struct WebMenuItem: Decodable, Equatable {
  public var separator: Bool
  public var title: String?
  public var actionID: String?
  public var stateGetterID: String?
  public var key: String?
  public var modifiers: [String]?
  public var children: [Self]?

  public init(separator: Bool, title: String?, actionID: String?, stateGetterID: String?, key: String?, modifiers: [String]?, children: [Self]?) {
    self.separator = separator
    self.title = title
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
