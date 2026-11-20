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

  public func getMenuItemStates(ids: [String]) async throws -> [WebToolbarItemState] {
    let message = BridgeMessage(
      ("ids", ids)
    )

    guard let webView else {
      throw WKWebView.InvokeError.unexpectedNil
    }

    return try await webView.invoke(path: "webModules.api.getMenuItemStates", message: message)
  }
}

public struct MenuItemState: Codable, Sendable {
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

/// State snapshot for a toolbar control or menu entry.
public struct WebToolbarItemState: Codable, Sendable {
  public var isEnabled: Bool?
  public var isSelected: Bool?
  public var title: String?
  public var icon: String?

  public init(isEnabled: Bool?, isSelected: Bool?, title: String?, icon: String?) {
    self.isEnabled = isEnabled
    self.isSelected = isSelected
    self.title = title
    self.icon = icon
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: BridgeFieldKey.self)
    isEnabled = try container.value("isEnabled")
    isSelected = try container.value("isSelected")
    title = try container.value("title")
    icon = try container.value("icon")
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: BridgeFieldKey.self)
    try container.encode(isEnabled, forKey: "isEnabled")
    try container.encode(isSelected, forKey: "isSelected")
    try container.encode(title, forKey: "title")
    try container.encode(icon, forKey: "icon")
  }
}
