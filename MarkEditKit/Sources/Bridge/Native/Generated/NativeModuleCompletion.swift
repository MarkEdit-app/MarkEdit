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
  func requestCompletions(anchor: TextTokenizeAnchor, fullText: String?, userInitiated: Bool)
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
      return requestCompletions(parameters: parameters)
    case "commitCompletion":
      return commitCompletion(parameters: parameters)
    case "cancelCompletion":
      return cancelCompletion(parameters: parameters)
    case "selectPrevious":
      return selectPrevious(parameters: parameters)
    case "selectNext":
      return selectNext(parameters: parameters)
    case "selectTop":
      return selectTop(parameters: parameters)
    case "selectBottom":
      return selectBottom(parameters: parameters)
    default:
      return nil
    }
  }

  private func requestCompletions(parameters: Data) -> Result<Any?, Error>? {
    let parameter_anchor: TextTokenizeAnchor
    let parameter_fullText: String?
    let parameter_userInitiated: Bool

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_anchor = try container.value("anchor")
      parameter_fullText = try container.value("fullText")
      parameter_userInitiated = try container.value("userInitiated")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    module.requestCompletions(anchor: parameter_anchor, fullText: parameter_fullText, userInitiated: parameter_userInitiated)
    return .success(nil)
  }

  private func commitCompletion(parameters: Data) -> Result<Any?, Error>? {
    let parameter_insert: String?

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_insert = try container.value("insert")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    module.commitCompletion(insert: parameter_insert)
    return .success(nil)
  }

  private func cancelCompletion(parameters: Data) -> Result<Any?, Error>? {
    module.cancelCompletion()
    return .success(nil)
  }

  private func selectPrevious(parameters: Data) -> Result<Any?, Error>? {
    module.selectPrevious()
    return .success(nil)
  }

  private func selectNext(parameters: Data) -> Result<Any?, Error>? {
    module.selectNext()
    return .success(nil)
  }

  private func selectTop(parameters: Data) -> Result<Any?, Error>? {
    module.selectTop()
    return .success(nil)
  }

  private func selectBottom(parameters: Data) -> Result<Any?, Error>? {
    module.selectBottom()
    return .success(nil)
  }
}
