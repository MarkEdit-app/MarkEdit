//
//  NativeModuleTokenizer.swift
//
//  Generated using https://github.com/microsoft/ts-gyb
//
//  Don't modify this file manually, it's auto generated.
//
//  To make changes, edit template files under /CoreEditor/src/@codegen

import Foundation
import MarkEditCore

@MainActor
public protocol NativeModuleTokenizer: NativeModule {
  func tokenize(anchor: TextTokenizeAnchor) async -> [String: Any]
  func moveWordBackward(anchor: TextTokenizeAnchor) async -> Int
  func moveWordForward(anchor: TextTokenizeAnchor) async -> Int
}

public extension NativeModuleTokenizer {
  var bridge: NativeBridge { NativeBridgeTokenizer(self) }
}

@MainActor
final class NativeBridgeTokenizer: NativeBridge {
  static let name = "tokenizer"

  private let module: NativeModuleTokenizer
  private lazy var decoder = JSONDecoder()

  init(_ module: NativeModuleTokenizer) {
    self.module = module
  }

  func invoke(method: String, parameters: Data) async -> Result<Any?, Error>? {
    switch method {
    case "tokenize":
      return await tokenize(parameters: parameters)
    case "moveWordBackward":
      return await moveWordBackward(parameters: parameters)
    case "moveWordForward":
      return await moveWordForward(parameters: parameters)
    default:
      return nil
    }
  }

  private func tokenize(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var anchor: TextTokenizeAnchor

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        anchor = try container.value("anchor")
      }
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.tokenize(anchor: message.anchor)
    return .success(result)
  }

  private func moveWordBackward(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var anchor: TextTokenizeAnchor

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        anchor = try container.value("anchor")
      }
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.moveWordBackward(anchor: message.anchor)
    return .success(result)
  }

  private func moveWordForward(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var anchor: TextTokenizeAnchor

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        anchor = try container.value("anchor")
      }
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.moveWordForward(anchor: message.anchor)
    return .success(result)
  }
}
