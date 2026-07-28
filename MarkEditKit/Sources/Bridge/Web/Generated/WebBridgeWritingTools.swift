//
//  WebBridgeWritingTools.swift
//
//  Generated using https://github.com/microsoft/ts-gyb
//
//  Don't modify this file manually, it's auto generated.
//
//  To make changes, edit template files under /CoreEditor/src/@codegen

import WebKit
import MarkEditCore

@MainActor
public final class WebBridgeWritingTools {
  private weak var webView: WKWebView?

  init(webView: WKWebView) {
    self.webView = webView
  }

  public func setActive(isActive: Bool, reselect: Bool, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    let message = BridgeMessage(
      ("isActive", isActive),
      ("reselect", reselect)
    )

    webView?.invoke(path: "webModules.writingTools.setActive", message: message, completion: completion)
  }

  public func ensureSelectionRect(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.writingTools.ensureSelectionRect", completion: completion)
  }
}
