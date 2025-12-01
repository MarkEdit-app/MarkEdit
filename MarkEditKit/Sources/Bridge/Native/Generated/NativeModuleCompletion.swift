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

@MainActor
public protocol NativeModuleCompletion: NativeModule {
  func requestCompletions(anchor: TextTokenizeAnchor, fullText: String?)
  func commitCompletion(insert: String?)
  func cancelCompletion()
  func selectPrevious()
  func selectNext()
  func selectTop()
  func selectBottom()
}

public extension NativeModuleCompletion {
  var bridge: NativeBridge { NativeBridgeCompletion(self) }
}

@MainActor
final class NativeBridgeCompletion: NativeBridge {
  static let name = "completion"
  lazy var methods: [String: NativeMethod] = [
    "requestCompletions": { [weak self] in
      await self?.requestCompletions(parameters: $0)
    },
    "commitCompletion": { [weak self] in
      await self?.commitCompletion(parameters: $0)
    },
    "cancelCompletion": { [weak self] in
      await self?.cancelCompletion(parameters: $0)
    },
    "selectPrevious": { [weak self] in
      await self?.selectPrevious(parameters: $0)
    },
    "selectNext": { [weak self] in
      await self?.selectNext(parameters: $0)
    },
    "selectTop": { [weak self] in
      await self?.selectTop(parameters: $0)
    },
    "selectBottom": { [weak self] in
      await self?.selectBottom(parameters: $0)
    },
  ]

  private let module: NativeModuleCompletion
  private lazy var decoder = JSONDecoder()

  init(_ module: NativeModuleCompletion) {
    self.module = module
  }

  private func requestCompletions(parameters: Data) async -> Result<Any?, Error>? {
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

  private func commitCompletion(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var insert: String?
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    module.commitCompletion(insert: message.insert)
    return .success(nil)
  }

  private func cancelCompletion(parameters: Data) async -> Result<Any?, Error>? {
    module.cancelCompletion()
    return .success(nil)
  }

  private func selectPrevious(parameters: Data) async -> Result<Any?, Error>? {
    module.selectPrevious()
    return .success(nil)
  }

  private func selectNext(parameters: Data) async -> Result<Any?, Error>? {
    module.selectNext()
    return .success(nil)
  }

  private func selectTop(parameters: Data) async -> Result<Any?, Error>? {
    module.selectTop()
    return .success(nil)
  }

  private func selectBottom(parameters: Data) async -> Result<Any?, Error>? {
    module.selectBottom()
    return .success(nil)
  }
}
