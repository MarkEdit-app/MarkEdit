//
//  NativeModulePreview.swift
//
//  Generated using https://github.com/microsoft/ts-gyb
//
//  Don't modify this file manually, it's auto generated.
//
//  To make changes, edit template files under /CoreEditor/src/@codegen

import Foundation
import MarkEditCore

@MainActor
public protocol NativeModulePreview: NativeModule {
  func show(code: String, type: PreviewType, rect: WebRect)
}

public extension NativeModulePreview {
  var bridge: NativeBridge { NativeBridgePreview(self) }
}

@MainActor
final class NativeBridgePreview: NativeBridge {
  static let name = "preview"

  private let module: NativeModulePreview
  private lazy var decoder = JSONDecoder()

  init(_ module: NativeModulePreview) {
    self.module = module
  }

  func invoke(method: String, parameters: Data) async -> Result<Any?, Error>? {
    switch method {
    case "show":
      return await show(parameters: parameters)
    default:
      return nil
    }
  }

  private func show(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var code: String
      var type: PreviewType
      var rect: WebRect

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        code = try container.value("code")
        type = try container.value("type")
        rect = try container.value("rect")
      }
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    module.show(code: message.code, type: message.type, rect: message.rect)
    return .success(nil)
  }
}

public enum PreviewType: String, Codable {
  case mermaid = "mermaid"
  case katex = "katex"
  case table = "table"
}
