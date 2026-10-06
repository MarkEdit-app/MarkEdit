//
//  NativeModuleSecretStorage.swift
//
//  Generated using https://github.com/microsoft/ts-gyb
//
//  Don't modify this file manually, it's auto generated.
//
//  To make changes, edit template files under /CoreEditor/src/@codegen

import Foundation
import MarkEditCore

@MainActor
public protocol NativeModuleSecretStorage: NativeModule {
  func has(path: String, key: String) async -> String
  func get(path: String, key: String) async -> String
  func set(path: String, key: String, value: String) async -> String
  func delete(path: String, key: String) async -> String
}

public extension NativeModuleSecretStorage {
  var bridge: NativeBridge { NativeBridgeSecretStorage(self) }
}

@MainActor
final class NativeBridgeSecretStorage: NativeBridge {
  static let name = "secretStorage"

  private let module: NativeModuleSecretStorage
  private lazy var decoder = JSONDecoder()

  init(_ module: NativeModuleSecretStorage) {
    self.module = module
  }

  func invoke(method: String, parameters: Data) async -> Result<Any?, Error>? {
    switch method {
    case "has":
      return await has(parameters: parameters)
    case "get":
      return await get(parameters: parameters)
    case "set":
      return await set(parameters: parameters)
    case "delete":
      return await delete(parameters: parameters)
    default:
      return nil
    }
  }

  private func has(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var path: String
      var key: String

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        path = try container.value("path")
        key = try container.value("key")
      }
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.has(path: message.path, key: message.key)
    return .success(result)
  }

  private func get(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var path: String
      var key: String

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        path = try container.value("path")
        key = try container.value("key")
      }
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.get(path: message.path, key: message.key)
    return .success(result)
  }

  private func set(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var path: String
      var key: String
      var value: String

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        path = try container.value("path")
        key = try container.value("key")
        value = try container.value("value")
      }
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.set(path: message.path, key: message.key, value: message.value)
    return .success(result)
  }

  private func delete(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var path: String
      var key: String

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        path = try container.value("path")
        key = try container.value("key")
      }
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.delete(path: message.path, key: message.key)
    return .success(result)
  }
}
