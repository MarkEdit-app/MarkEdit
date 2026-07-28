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

  private let module: NativeModuleCompletion
  private lazy var decoder = JSONDecoder()

  init(_ module: NativeModuleCompletion) {
    self.module = module
  }

  func invoke(method: String, parameters: Data) async -> Result<Any?, Error>? {
    switch method {
    case "requestCompletions":
      return await requestCompletions(parameters: parameters)
    case "commitCompletion":
      return await commitCompletion(parameters: parameters)
    case "cancelCompletion":
      return await cancelCompletion(parameters: parameters)
    case "selectPrevious":
      return await selectPrevious(parameters: parameters)
    case "selectNext":
      return await selectNext(parameters: parameters)
    case "selectTop":
      return await selectTop(parameters: parameters)
    case "selectBottom":
      return await selectBottom(parameters: parameters)
    default:
      return nil
    }
  }

  private func requestCompletions(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var anchor: TextTokenizeAnchor
      var fullText: String?

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        anchor = try container.value("anchor")
        fullText = try container.value("fullText")
      }
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

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        insert = try container.value("insert")
      }
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
