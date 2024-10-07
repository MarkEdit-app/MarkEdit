//
//  NativeModuleUI.swift
//
//  Generated using https://github.com/microsoft/ts-gyb
//
//  Don't modify this file manually, it's auto generated.
//
//  To make changes, edit template files under /CoreEditor/src/@codegen

import Foundation
import MarkEditCore

@MainActor
public protocol NativeModuleUI: NativeModule {
  func addMainMenuItems(items: [WebMenuItem])
  func showContextMenu(items: [WebMenuItem], location: WebPoint)
  func showAlert(title: String?, message: String?, buttons: [String]?) -> Int
  func showTextBox(title: String?, placeholder: String?, defaultValue: String?) -> String?
}

public extension NativeModuleUI {
  var bridge: NativeBridge { NativeBridgeUI(self) }
}

@MainActor
final class NativeBridgeUI: NativeBridge {
  static let name = "ui"
  lazy var methods: [String: NativeMethod] = [
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
  ]

  private let module: NativeModuleUI
  private lazy var decoder = JSONDecoder()

  init(_ module: NativeModuleUI) {
    self.module = module
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
}

/// Represents a menu item in native menus.
public struct WebMenuItem: Decodable, Equatable {
  public var id: String
  public var separator: Bool
  public var title: String?
  public var key: String?
  public var modifiers: [String]?
  public var children: [Self]?

  public init(id: String, separator: Bool, title: String?, key: String?, modifiers: [String]?, children: [Self]?) {
    self.id = id
    self.separator = separator
    self.title = title
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
