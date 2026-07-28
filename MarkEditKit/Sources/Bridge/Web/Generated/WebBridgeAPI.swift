//
//  WebBridgeAPI.swift
//
//  Generated using https://github.com/microsoft/ts-gyb
//
//  Don't modify this file manually, it's auto generated.
//
//  To make changes, edit template files under /CoreEditor/src/@codegen

import WebKit
import MarkEditCore

@MainActor
public final class WebBridgeAPI {
  private weak var webView: WKWebView?

  init(webView: WKWebView) {
    self.webView = webView
  }

  public func notifyAppReady(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.api.notifyAppReady", completion: completion)
  }

  public func handleMainMenuAction(id: String, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    let message = BridgeMessage(
      ("id", id)
    )

    webView?.invoke(path: "webModules.api.handleMainMenuAction", message: message, completion: completion)
  }

  public func handleContextMenuAction(id: String, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    let message = BridgeMessage(
      ("id", id)
    )

    webView?.invoke(path: "webModules.api.handleContextMenuAction", message: message, completion: completion)
  }

  public func getMenuItemState(id: String) async throws -> MenuItemState {
    let message = BridgeMessage(
      ("id", id)
    )

    guard let webView else {
      throw WKWebView.InvokeError.unexpectedNil
    }

    return try await webView.invoke(path: "webModules.api.getMenuItemState", message: message)
  }
}

public struct MenuItemState: Codable {
  /// Whether enabled; defaults to true.
  public var isEnabled: Bool?
  /// Whether selected; defaults to false.
  public var isSelected: Bool?

  public init(isEnabled: Bool?, isSelected: Bool?) {
    self.isEnabled = isEnabled
    self.isSelected = isSelected
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: BridgeFieldKey.self)
    isEnabled = try container.value("isEnabled")
    isSelected = try container.value("isSelected")
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: BridgeFieldKey.self)
    try container.encode(isEnabled, forKey: "isEnabled")
    try container.encode(isSelected, forKey: "isSelected")
  }
}
