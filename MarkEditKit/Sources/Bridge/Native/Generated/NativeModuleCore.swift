//
//  NativeModuleCore.swift
//
//  Generated using https://github.com/microsoft/ts-gyb
//
//  Don't modify this file manually, it's auto generated.
//
//  To make changes, edit template files under /CoreEditor/src/@codegen

import Foundation
import MarkEditCore

public protocol NativeModuleCore: NativeModule {
  func notifyWindowDidLoad()
  func notifyTextDidChange()
  func notifySelectionDidChange(lineColumn: LineColumnInfo, contentEdited: Bool)
}

public extension NativeModuleCore {
  var bridge: NativeBridge { NativeBridgeCore(self) }
}

final class NativeBridgeCore: NativeBridge {
  static let name = "core"
  lazy var methods: [String: NativeMethod] = [
    "notifyWindowDidLoad": { [weak self] in
      await self?.notifyWindowDidLoad(parameters: $0)
    },
    "notifyTextDidChange": { [weak self] in
      await self?.notifyTextDidChange(parameters: $0)
    },
    "notifySelectionDidChange": { [weak self] in
      await self?.notifySelectionDidChange(parameters: $0)
    },
  ]

  private let module: NativeModuleCore
  private lazy var decoder = JSONDecoder()

  init(_ module: NativeModuleCore) {
    self.module = module
  }

  @MainActor private func notifyWindowDidLoad(parameters: Data) async -> Result<Encodable?, Error>? {
    module.notifyWindowDidLoad()
    return .success(nil)
  }

  @MainActor private func notifyTextDidChange(parameters: Data) async -> Result<Encodable?, Error>? {
    module.notifyTextDidChange()
    return .success(nil)
  }

  @MainActor private func notifySelectionDidChange(parameters: Data) async -> Result<Encodable?, Error>? {
    struct Message: Decodable {
      var lineColumn: LineColumnInfo
      var contentEdited: Bool
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    module.notifySelectionDidChange(lineColumn: message.lineColumn, contentEdited: message.contentEdited)
    return .success(nil)
  }
}

public struct LineColumnInfo: Decodable, Equatable {
  public var line: Int
  public var column: Int
  public var length: Int

  public init(line: Int, column: Int, length: Int) {
    self.line = line
    self.column = column
    self.length = length
  }
}
