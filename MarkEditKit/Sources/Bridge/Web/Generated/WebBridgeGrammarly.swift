//
//  WebBridgeGrammarly.swift
//
//  Generated using https://github.com/microsoft/ts-gyb
//
//  Don't modify this file manually, it's auto generated.
//
//  To make changes, edit template files under /CoreEditor/src/@codegen

import WebKit
import MarkEditCore

public final class WebBridgeGrammarly {
  private weak var webView: WKWebView?

  init(webView: WKWebView) {
    self.webView = webView
  }

  public func connect(clientID: String, redirectURI: String, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let clientID: String
      let redirectURI: String
    }

    let message = Message(
      clientID: clientID,
      redirectURI: redirectURI
    )

    webView?.invoke(path: "webModules.grammarly.connect", message: message, completion: completion)
  }

  public func disconnect(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.grammarly.disconnect", completion: completion)
  }

  public func completeOAuth(url: String, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let url: String
    }

    let message = Message(
      url: url
    )

    webView?.invoke(path: "webModules.grammarly.completeOAuth", message: message, completion: completion)
  }
}
