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

public protocol NativeModuleTokenizer: NativeModule {
  func tokenize(anchor: TextTokenizeAnchor) -> TextTokenizeResult
  func moveWordBackward(anchor: TextTokenizeAnchor) -> Int
  func moveWordForward(anchor: TextTokenizeAnchor) -> Int
}

public extension NativeModuleTokenizer {
  var bridge: NativeBridge { NativeBridgeTokenizer(self) }
}

final class NativeBridgeTokenizer: NativeBridge {
  static let name = "tokenizer"
  lazy var methods: [String: NativeMethod] = [
    "tokenize": { [weak self] in
      self?.tokenize(parameters: $0)
    },
    "moveWordBackward": { [weak self] in
      self?.moveWordBackward(parameters: $0)
    },
    "moveWordForward": { [weak self] in
      self?.moveWordForward(parameters: $0)
    },
  ]

  private let module: NativeModuleTokenizer
  private lazy var decoder = JSONDecoder()

  init(_ module: NativeModuleTokenizer) {
    self.module = module
  }

  private func tokenize(parameters: Data) -> Result<Encodable?, Error>? {
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

    let result = module.tokenize(anchor: message.anchor)
    return .success(result)
  }

  private func moveWordBackward(parameters: Data) -> Result<Encodable?, Error>? {
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

    let result = module.moveWordBackward(anchor: message.anchor)
    return .success(result)
  }

  private func moveWordForward(parameters: Data) -> Result<Encodable?, Error>? {
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

    let result = module.moveWordForward(anchor: message.anchor)
    return .success(result)
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
