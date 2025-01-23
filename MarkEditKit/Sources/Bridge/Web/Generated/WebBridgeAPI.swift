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
}
