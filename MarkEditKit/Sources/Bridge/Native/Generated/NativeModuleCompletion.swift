//
//  NativeModuleCompletion.swift
//
//  Generated using https://github.com/microsoft/ts-gyb
//
//  Don't modify this file manually, it's auto generated.
//
//  To make changes, edit template files under /CoreEditor/src/@codegen

import Foundation
import MarkEditCore

public protocol NativeModuleCompletion: NativeModule {
  func requestCompletions(anchor: TextTokenizeAnchor, fullText: String?)
  func commitCompletion()
  func cancelCompletion()
  func selectPrevious()
  func selectNext()
  func selectTop()
  func selectBottom()
}

public extension NativeModuleCompletion {
  var bridge: NativeBridge { NativeBridgeCompletion(self) }
}

final class NativeBridgeCompletion: NativeBridge {
  static let name = "completion"
  lazy var methods: [String: NativeMethod] = [
    "requestCompletions": { [weak self] in
      self?.requestCompletions(parameters: $0)
    },
    "commitCompletion": { [weak self] in
      self?.commitCompletion(parameters: $0)
    },
    "cancelCompletion": { [weak self] in
      self?.cancelCompletion(parameters: $0)
    },
    "selectPrevious": { [weak self] in
      self?.selectPrevious(parameters: $0)
    },
    "selectNext": { [weak self] in
      self?.selectNext(parameters: $0)
    },
    "selectTop": { [weak self] in
      self?.selectTop(parameters: $0)
    },
    "selectBottom": { [weak self] in
      self?.selectBottom(parameters: $0)
    },
  ]

  private let module: NativeModuleCompletion
  private lazy var decoder = JSONDecoder()

  init(_ module: NativeModuleCompletion) {
    self.module = module
  }

  private func requestCompletions(parameters: Data) -> Result<Encodable?, Error>? {
    struct Message: Decodable {
      var anchor: TextTokenizeAnchor
      var fullText: String?
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    module.requestCompletions(anchor: message.anchor, fullText: message.fullText)
    return .success(nil)
  }

  private func commitCompletion(parameters: Data) -> Result<Encodable?, Error>? {
    module.commitCompletion()
    return .success(nil)
  }

  private func cancelCompletion(parameters: Data) -> Result<Encodable?, Error>? {
    module.cancelCompletion()
    return .success(nil)
  }

  private func selectPrevious(parameters: Data) -> Result<Encodable?, Error>? {
    module.selectPrevious()
    return .success(nil)
  }

  private func selectNext(parameters: Data) -> Result<Encodable?, Error>? {
    module.selectNext()
    return .success(nil)
  }

  private func selectTop(parameters: Data) -> Result<Encodable?, Error>? {
    module.selectTop()
    return .success(nil)
  }

  private func selectBottom(parameters: Data) -> Result<Encodable?, Error>? {
    module.selectBottom()
    return .success(nil)
  }
}
