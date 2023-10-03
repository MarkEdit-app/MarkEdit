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
  func notifyViewDidUpdate(contentEdited: Bool, compositionEnded: Bool, isDirty: Bool, selectedLineColumn: LineColumnInfo)
  func notifyContentOffsetDidChange()
  func notifyCompositionEnded(selectedLineColumn: LineColumnInfo)
  func notifyLinkClicked(link: String)
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
    "notifyContentOffsetDidChange": { [weak self] in
      self?.notifyContentOffsetDidChange(parameters: $0)
    },
    "notifyCompositionEnded": { [weak self] in
      self?.notifyCompositionEnded(parameters: $0)
    },
    "notifyLinkClicked": { [weak self] in
      self?.notifyLinkClicked(parameters: $0)
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
      var compositionEnded: Bool
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

    module.notifyViewDidUpdate(contentEdited: message.contentEdited, compositionEnded: message.compositionEnded, isDirty: message.isDirty, selectedLineColumn: message.selectedLineColumn)
    return .success(nil)
  }

  private func notifyContentOffsetDidChange(parameters: Data) -> Result<Any?, Error>? {
    module.notifyContentOffsetDidChange()
    return .success(nil)
  }

  private func notifyCompositionEnded(parameters: Data) -> Result<Any?, Error>? {
    struct Message: Decodable {
      var selectedLineColumn: LineColumnInfo
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    module.notifyCompositionEnded(selectedLineColumn: message.selectedLineColumn)
    return .success(nil)
  }

  private func notifyLinkClicked(parameters: Data) -> Result<Any?, Error>? {
    struct Message: Decodable {
      var link: String
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    module.notifyLinkClicked(link: message.link)
    return .success(nil)
  }
}

public struct LineColumnInfo: Decodable, Equatable {
  public var lineNumber: Int
  public var columnText: String
  public var selectionText: String

  public init(lineNumber: Int, columnText: String, selectionText: String) {
    self.lineNumber = lineNumber
    self.columnText = columnText
    self.selectionText = selectionText
  }
}
