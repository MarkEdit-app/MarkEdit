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
  func has(capability: String?, key: String) async -> String
  func get(capability: String?, key: String) async -> String
  func set(capability: String?, key: String, value: String) async -> String
  func delete(capability: String?, key: String) async -> String
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
    let parameter_capability: String?
    let parameter_key: String

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_capability = try container.value("capability")
      parameter_key = try container.value("key")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.has(capability: parameter_capability, key: parameter_key)
    return .success(result)
  }

  private func get(parameters: Data) async -> Result<Any?, Error>? {
    let parameter_capability: String?
    let parameter_key: String

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_capability = try container.value("capability")
      parameter_key = try container.value("key")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.get(capability: parameter_capability, key: parameter_key)
    return .success(result)
  }

  private func set(parameters: Data) async -> Result<Any?, Error>? {
    let parameter_capability: String?
    let parameter_key: String
    let parameter_value: String

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_capability = try container.value("capability")
      parameter_key = try container.value("key")
      parameter_value = try container.value("value")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.set(capability: parameter_capability, key: parameter_key, value: parameter_value)
    return .success(result)
  }

  private func delete(parameters: Data) async -> Result<Any?, Error>? {
    let parameter_capability: String?
    let parameter_key: String

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_capability = try container.value("capability")
      parameter_key = try container.value("key")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.delete(capability: parameter_capability, key: parameter_key)
    return .success(result)
  }
}
