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

public protocol NativeModulePreview: NativeModule {
  func show(code: String, type: PreviewType, rect: JSRect)
}

public extension NativeModulePreview {
  var bridge: NativeBridge { NativeBridgePreview(self) }
}

final class NativeBridgePreview: NativeBridge {
  static let name = "preview"
  lazy var methods: [String: NativeMethod] = [
    "show": { [weak self] in
      await self?.show(parameters: $0)
    },
  ]

  private let module: NativeModulePreview
  private lazy var decoder = JSONDecoder()

  init(_ module: NativeModulePreview) {
    self.module = module
  }

  @MainActor private func show(parameters: Data) async -> Result<Encodable?, Error>? {
    struct Message: Decodable {
      var code: String
      var type: PreviewType
      var rect: JSRect
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

/// "CGRect-fashion" rect.
public struct JSRect: Decodable, Equatable {
  public var x: Double
  public var y: Double
  public var width: Double
  public var height: Double

  public init(x: Double, y: Double, width: Double, height: Double) {
    self.x = x
    self.y = y
    self.width = width
    self.height = height
  }
}
