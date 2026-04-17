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

  public func handleMainMenuAction(id: String, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let id: String
    }

    let message = Message(
      id: id
    )

    webView?.invoke(path: "webModules.api.handleMainMenuAction", message: message, completion: completion)
  }

  public func handleContextMenuAction(id: String, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let id: String
    }

    let message = Message(
      id: id
    )

    webView?.invoke(path: "webModules.api.handleContextMenuAction", message: message, completion: completion)
  }

  public func getMenuItemState(id: String) async throws -> MenuItemState {
    struct Message: Encodable {
      let id: String
    }

    let message = Message(
      id: id
    )

    guard let webView else {
      throw WKWebView.InvokeError.unexpectedNil
    }

    return try await webView.invoke(path: "webModules.api.getMenuItemState", message: message)
  }
}

public struct MenuItemState: Codable, Equatable {
  /// Whether enabled; defaults to true.
  public var isEnabled: Bool?
  /// Whether selected; defaults to false.
  public var isSelected: Bool?

  public init(isEnabled: Bool?, isSelected: Bool?) {
    self.isEnabled = isEnabled
    self.isSelected = isSelected
  }
}
