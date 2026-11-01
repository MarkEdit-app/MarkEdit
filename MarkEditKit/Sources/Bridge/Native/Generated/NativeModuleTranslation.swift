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
    let parameter_text: String
    let parameter_from: String?
    let parameter_to: String?

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_text = try container.value("text")
      parameter_from = try container.value("from")
      parameter_to = try container.value("to")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.translate(text: parameter_text, from: parameter_from, to: parameter_to)
    return .success(result)
  }
}
