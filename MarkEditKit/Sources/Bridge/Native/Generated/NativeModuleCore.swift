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
  func notifyViewportScaleDidChange()
  func notifyViewDidUpdate(contentEdited: Bool, isDirty: Bool, selectedLineColumn: LineColumnInfo)
}

public extension NativeModuleCore {
  var bridge: NativeBridge { NativeBridgeCore(self) }
}

final class NativeBridgeCore: NativeBridge {
  static let name = "core"
  lazy var methods: [String: NativeMethod] = [
    "notifyWindowDidLoad": { [weak self] in
      self?.notifyWindowDidLoad(parameters: $0)
    },
    "notifyViewportScaleDidChange": { [weak self] in
      self?.notifyViewportScaleDidChange(parameters: $0)
    },
    "notifyViewDidUpdate": { [weak self] in
      self?.notifyViewDidUpdate(parameters: $0)
    },
  ]

  private let module: NativeModuleCore
  private lazy var decoder = JSONDecoder()

  init(_ module: NativeModuleCore) {
    self.module = module
  }

  private func notifyWindowDidLoad(parameters: Data) -> Result<Any?, Error>? {
    module.notifyWindowDidLoad()
    return .success(nil)
  }

  private func notifyViewportScaleDidChange(parameters: Data) -> Result<Any?, Error>? {
    module.notifyViewportScaleDidChange()
    return .success(nil)
  }

  private func notifyViewDidUpdate(parameters: Data) -> Result<Any?, Error>? {
    struct Message: Decodable {
      var contentEdited: Bool
      var isDirty: Bool
      var selectedLineColumn: LineColumnInfo
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    module.notifyViewDidUpdate(contentEdited: message.contentEdited, isDirty: message.isDirty, selectedLineColumn: message.selectedLineColumn)
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
