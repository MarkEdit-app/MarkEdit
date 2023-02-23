//
//  NativeModuleTokenizer.swift
//
//  Generated using https://github.com/microsoft/ts-gyb
//
//  Don't modify this file manually, it's auto generated.
//
//  To make changes, edit template files under /CoreEditor/src/@codegen

import Foundation

public protocol NativeModuleTokenizer: NativeModule {
  func tokenize(anchor: TextTokenizeAnchor) async -> TextTokenizeResult
}

public extension NativeModuleTokenizer {
  var bridge: NativeBridge { NativeBridgeTokenizer(self) }
}

final class NativeBridgeTokenizer: NativeBridge {
  static let name = "tokenizer"
  lazy var methods: [String: NativeMethod] = [
    "tokenize": { [weak self] in
      await self?.tokenize(parameters: $0)
    },
  ]

  private let module: NativeModuleTokenizer
  private lazy var decoder = JSONDecoder()

  init(_ module: NativeModuleTokenizer) {
    self.module = module
  }

  @MainActor private func tokenize(parameters: Data) async -> Result<Encodable?, Error>? {
    struct Message: Decodable {
      var anchor: TextTokenizeAnchor
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
}

public struct TextTokenizeAnchor: Decodable, Equatable {
  public var text: String
  public var pos: Int

  public init(text: String, pos: Int) {
    self.text = text
    self.pos = pos
  }
}

public struct TextTokenizeResult: Encodable, Equatable {
  public var from: Int
  public var to: Int

  public init(from: Int, to: Int) {
    self.from = from
    self.to = to
  }
}
