//
//  NativeModuleTranslation.swift
//
//  Generated using https://github.com/microsoft/ts-gyb
//
//  Don't modify this file manually, it's auto generated.
//
//  To make changes, edit template files under /CoreEditor/src/@codegen

import Foundation
import MarkEditCore

@MainActor
public protocol NativeModuleTranslation: NativeModule {
  func translate(text: String, from: String?, to: String?) async -> String
}

public extension NativeModuleTranslation {
  var bridge: NativeBridge { NativeBridgeTranslation(self) }
}

@MainActor
final class NativeBridgeTranslation: NativeBridge {
  static let name = "translation"

  private let module: NativeModuleTranslation
  private lazy var decoder = JSONDecoder()

  init(_ module: NativeModuleTranslation) {
    self.module = module
  }

  func invoke(method: String, parameters: Data) async -> Result<Any?, Error>? {
    switch method {
    case "translate":
      return await translate(parameters: parameters)
    default:
      return nil
    }
  }

  private func translate(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var text: String
      var from: String?
      var to: String?

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        text = try container.value("text")
        from = try container.value("from")
        to = try container.value("to")
      }
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.translate(text: message.text, from: message.from, to: message.to)
    return .success(result)
  }
}
