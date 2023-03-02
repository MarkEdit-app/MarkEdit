//
//  WebBridgeCompletion.swift
//
//  Generated using https://github.com/microsoft/ts-gyb
//
//  Don't modify this file manually, it's auto generated.
//
//  To make changes, edit template files under /CoreEditor/src/@codegen

import WebKit
import MarkEditCore

public final class WebBridgeCompletion {
  private weak var webView: WKWebView?

  init(webView: WKWebView) {
    self.webView = webView
  }

  public func startCompletion(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.completion.startCompletion", completion: completion)
  }

  public func setState(panelVisible: Bool, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let panelVisible: Bool
    }

    let message = Message(
      panelVisible: panelVisible
    )

    webView?.invoke(path: "webModules.completion.setState", message: message, completion: completion)
  }
}
