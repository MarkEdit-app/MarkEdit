//
//  NativeModulePDF.swift
//
//  Generated using https://github.com/microsoft/ts-gyb
//
//  Don't modify this file manually, it's auto generated.
//
//  To make changes, edit template files under /CoreEditor/src/@codegen

import Foundation
import MarkEditCore

@MainActor
public protocol NativeModulePDF: NativeModule {
  func generate(html: String, fileName: String?) async -> Bool
}

public extension NativeModulePDF {
  var bridge: NativeBridge { NativeBridgePDF(self) }
}

@MainActor
final class NativeBridgePDF: NativeBridge {
  static let name = "pdf"
  lazy var methods: [String: NativeMethod] = [
    "generate": { [weak self] in
      await self?.generate(parameters: $0)
    },
  ]

  private let module: NativeModulePDF
  private lazy var decoder = JSONDecoder()

  init(_ module: NativeModulePDF) {
    self.module = module
  }

  private func generate(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var html: String
      var fileName: String?
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.generate(html: message.html, fileName: message.fileName)
    return .success(result)
  }
}
