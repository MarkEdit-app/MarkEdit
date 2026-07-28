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

@MainActor
public protocol NativeModuleCore: NativeModule {
  func notifyWindowDidLoad()
  func notifyWindowResize(method: NativeModuleCoreNotifyWindowResizeMethod, width: Double, height: Double)
  func notifyWindowMove(method: NativeModuleCoreNotifyWindowMoveMethod, x: Double, y: Double)
  func notifyWindowClose()
  func notifyEditorDidBecomeIdle()
  func notifyBackgroundColorDidChange(color: Int, alpha: Double)
  func notifyViewportScaleDidChange()
  func notifyViewDidUpdate(contentEdited: Bool, compositionEnded: Bool, isDirty: Bool, selectedLineColumn: LineColumnInfo)
  func notifyContentHeightDidChange(bottomPanelHeight: Double)
  func notifyContentOffsetDidChange()
  func notifyCompositionEnded(selectedLineColumn: LineColumnInfo)
  func notifyLinkClicked(link: String)
  func notifyLightWarning()
}

public extension NativeModuleCore {
  var bridge: NativeBridge { NativeBridgeCore(self) }
}

@MainActor
final class NativeBridgeCore: NativeBridge {
  static let name = "core"

  private let module: NativeModuleCore
  private lazy var decoder = JSONDecoder()

  init(_ module: NativeModuleCore) {
    self.module = module
  }

  func invoke(method: String, parameters: Data) async -> Result<Any?, Error>? {
    switch method {
    case "notifyWindowDidLoad":
      return await notifyWindowDidLoad(parameters: parameters)
    case "notifyWindowResize":
      return await notifyWindowResize(parameters: parameters)
    case "notifyWindowMove":
      return await notifyWindowMove(parameters: parameters)
    case "notifyWindowClose":
      return await notifyWindowClose(parameters: parameters)
    case "notifyEditorDidBecomeIdle":
      return await notifyEditorDidBecomeIdle(parameters: parameters)
    case "notifyBackgroundColorDidChange":
      return await notifyBackgroundColorDidChange(parameters: parameters)
    case "notifyViewportScaleDidChange":
      return await notifyViewportScaleDidChange(parameters: parameters)
    case "notifyViewDidUpdate":
      return await notifyViewDidUpdate(parameters: parameters)
    case "notifyContentHeightDidChange":
      return await notifyContentHeightDidChange(parameters: parameters)
    case "notifyContentOffsetDidChange":
      return await notifyContentOffsetDidChange(parameters: parameters)
    case "notifyCompositionEnded":
      return await notifyCompositionEnded(parameters: parameters)
    case "notifyLinkClicked":
      return await notifyLinkClicked(parameters: parameters)
    case "notifyLightWarning":
      return await notifyLightWarning(parameters: parameters)
    default:
      return nil
    }
  }

  private func notifyWindowDidLoad(parameters: Data) async -> Result<Any?, Error>? {
    module.notifyWindowDidLoad()
    return .success(nil)
  }

  private func notifyWindowResize(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var method: NativeModuleCoreNotifyWindowResizeMethod
      var width: Double
      var height: Double

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        method = try container.value("method")
        width = try container.value("width")
        height = try container.value("height")
      }
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    module.notifyWindowResize(method: message.method, width: message.width, height: message.height)
    return .success(nil)
  }

  private func notifyWindowMove(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var method: NativeModuleCoreNotifyWindowMoveMethod
      var x: Double
      var y: Double

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        method = try container.value("method")
        x = try container.value("x")
        y = try container.value("y")
      }
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    module.notifyWindowMove(method: message.method, x: message.x, y: message.y)
    return .success(nil)
  }

  private func notifyWindowClose(parameters: Data) async -> Result<Any?, Error>? {
    module.notifyWindowClose()
    return .success(nil)
  }

  private func notifyEditorDidBecomeIdle(parameters: Data) async -> Result<Any?, Error>? {
    module.notifyEditorDidBecomeIdle()
    return .success(nil)
  }

  private func notifyBackgroundColorDidChange(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var color: Int
      var alpha: Double

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        color = try container.value("color")
        alpha = try container.value("alpha")
      }
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    module.notifyBackgroundColorDidChange(color: message.color, alpha: message.alpha)
    return .success(nil)
  }

  private func notifyViewportScaleDidChange(parameters: Data) async -> Result<Any?, Error>? {
    module.notifyViewportScaleDidChange()
    return .success(nil)
  }

  private func notifyViewDidUpdate(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var contentEdited: Bool
      var compositionEnded: Bool
      var isDirty: Bool
      var selectedLineColumn: LineColumnInfo

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        contentEdited = try container.value("contentEdited")
        compositionEnded = try container.value("compositionEnded")
        isDirty = try container.value("isDirty")
        selectedLineColumn = try container.value("selectedLineColumn")
      }
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

  private func notifyContentHeightDidChange(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var bottomPanelHeight: Double

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        bottomPanelHeight = try container.value("bottomPanelHeight")
      }
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    module.notifyContentHeightDidChange(bottomPanelHeight: message.bottomPanelHeight)
    return .success(nil)
  }

  private func notifyContentOffsetDidChange(parameters: Data) async -> Result<Any?, Error>? {
    module.notifyContentOffsetDidChange()
    return .success(nil)
  }

  private func notifyCompositionEnded(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var selectedLineColumn: LineColumnInfo

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        selectedLineColumn = try container.value("selectedLineColumn")
      }
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

  private func notifyLinkClicked(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var link: String

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        link = try container.value("link")
      }
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

  private func notifyLightWarning(parameters: Data) async -> Result<Any?, Error>? {
    module.notifyLightWarning()
    return .success(nil)
  }
}

public enum NativeModuleCoreNotifyWindowResizeMethod: String, Codable {
  case to = "to"
  case by = "by"
}

public enum NativeModuleCoreNotifyWindowMoveMethod: String, Codable {
  case to = "to"
  case by = "by"
}

public struct LineColumnInfo: Decodable {
  public var contentLength: Int
  public var lineNumber: Int
  public var columnText: String
  public var selectionText: String
  public var selectionRange: SelectionRange?

  public init(contentLength: Int, lineNumber: Int, columnText: String, selectionText: String, selectionRange: SelectionRange?) {
    self.contentLength = contentLength
    self.lineNumber = lineNumber
    self.columnText = columnText
    self.selectionText = selectionText
    self.selectionRange = selectionRange
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: BridgeFieldKey.self)
    contentLength = try container.value("contentLength")
    lineNumber = try container.value("lineNumber")
    columnText = try container.value("columnText")
    selectionText = try container.value("selectionText")
    selectionRange = try container.value("selectionRange")
  }
}
