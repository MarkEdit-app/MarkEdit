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
      return notifyWindowDidLoad(parameters: parameters)
    case "notifyWindowResize":
      return notifyWindowResize(parameters: parameters)
    case "notifyWindowMove":
      return notifyWindowMove(parameters: parameters)
    case "notifyWindowClose":
      return notifyWindowClose(parameters: parameters)
    case "notifyEditorDidBecomeIdle":
      return notifyEditorDidBecomeIdle(parameters: parameters)
    case "notifyBackgroundColorDidChange":
      return notifyBackgroundColorDidChange(parameters: parameters)
    case "notifyViewportScaleDidChange":
      return notifyViewportScaleDidChange(parameters: parameters)
    case "notifyViewDidUpdate":
      return notifyViewDidUpdate(parameters: parameters)
    case "notifyContentHeightDidChange":
      return notifyContentHeightDidChange(parameters: parameters)
    case "notifyContentOffsetDidChange":
      return notifyContentOffsetDidChange(parameters: parameters)
    case "notifyCompositionEnded":
      return notifyCompositionEnded(parameters: parameters)
    case "notifyLinkClicked":
      return notifyLinkClicked(parameters: parameters)
    case "notifyLightWarning":
      return notifyLightWarning(parameters: parameters)
    default:
      return nil
    }
  }

  private func notifyWindowDidLoad(parameters: Data) -> Result<Any?, Error>? {
    module.notifyWindowDidLoad()
    return .success(nil)
  }

  private func notifyWindowResize(parameters: Data) -> Result<Any?, Error>? {
    let parameter_method: NativeModuleCoreNotifyWindowResizeMethod
    let parameter_width: Double
    let parameter_height: Double

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_method = try container.value("method")
      parameter_width = try container.value("width")
      parameter_height = try container.value("height")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    module.notifyWindowResize(method: parameter_method, width: parameter_width, height: parameter_height)
    return .success(nil)
  }

  private func notifyWindowMove(parameters: Data) -> Result<Any?, Error>? {
    let parameter_method: NativeModuleCoreNotifyWindowMoveMethod
    let parameter_x: Double
    let parameter_y: Double

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_method = try container.value("method")
      parameter_x = try container.value("x")
      parameter_y = try container.value("y")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    module.notifyWindowMove(method: parameter_method, x: parameter_x, y: parameter_y)
    return .success(nil)
  }

  private func notifyWindowClose(parameters: Data) -> Result<Any?, Error>? {
    module.notifyWindowClose()
    return .success(nil)
  }

  private func notifyEditorDidBecomeIdle(parameters: Data) -> Result<Any?, Error>? {
    module.notifyEditorDidBecomeIdle()
    return .success(nil)
  }

  private func notifyBackgroundColorDidChange(parameters: Data) -> Result<Any?, Error>? {
    let parameter_color: Int
    let parameter_alpha: Double

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_color = try container.value("color")
      parameter_alpha = try container.value("alpha")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    module.notifyBackgroundColorDidChange(color: parameter_color, alpha: parameter_alpha)
    return .success(nil)
  }

  private func notifyViewportScaleDidChange(parameters: Data) -> Result<Any?, Error>? {
    module.notifyViewportScaleDidChange()
    return .success(nil)
  }

  private func notifyViewDidUpdate(parameters: Data) -> Result<Any?, Error>? {
    let parameter_contentEdited: Bool
    let parameter_compositionEnded: Bool
    let parameter_isDirty: Bool
    let parameter_selectedLineColumn: LineColumnInfo

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_contentEdited = try container.value("contentEdited")
      parameter_compositionEnded = try container.value("compositionEnded")
      parameter_isDirty = try container.value("isDirty")
      parameter_selectedLineColumn = try container.value("selectedLineColumn")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    module.notifyViewDidUpdate(contentEdited: parameter_contentEdited, compositionEnded: parameter_compositionEnded, isDirty: parameter_isDirty, selectedLineColumn: parameter_selectedLineColumn)
    return .success(nil)
  }

  private func notifyContentHeightDidChange(parameters: Data) -> Result<Any?, Error>? {
    let parameter_bottomPanelHeight: Double

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_bottomPanelHeight = try container.value("bottomPanelHeight")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    module.notifyContentHeightDidChange(bottomPanelHeight: parameter_bottomPanelHeight)
    return .success(nil)
  }

  private func notifyContentOffsetDidChange(parameters: Data) -> Result<Any?, Error>? {
    module.notifyContentOffsetDidChange()
    return .success(nil)
  }

  private func notifyCompositionEnded(parameters: Data) -> Result<Any?, Error>? {
    let parameter_selectedLineColumn: LineColumnInfo

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_selectedLineColumn = try container.value("selectedLineColumn")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    module.notifyCompositionEnded(selectedLineColumn: parameter_selectedLineColumn)
    return .success(nil)
  }

  private func notifyLinkClicked(parameters: Data) -> Result<Any?, Error>? {
    let parameter_link: String

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_link = try container.value("link")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    module.notifyLinkClicked(link: parameter_link)
    return .success(nil)
  }

  private func notifyLightWarning(parameters: Data) -> Result<Any?, Error>? {
    module.notifyLightWarning()
    return .success(nil)
  }
}

public enum NativeModuleCoreNotifyWindowResizeMethod: String, Codable, Sendable {
  case to = "to"
  case by = "by"
}

public enum NativeModuleCoreNotifyWindowMoveMethod: String, Codable, Sendable {
  case to = "to"
  case by = "by"
}

public struct LineColumnInfo: Decodable, Sendable {
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
