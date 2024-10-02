//
//  WebBridgeDummy.swift
//
//  Generated using https://github.com/microsoft/ts-gyb
//
//  Don't modify this file manually, it's auto generated.
//
//  To make changes, edit template files under /CoreEditor/src/@codegen

import WebKit
import MarkEditCore

@MainActor
public final class WebBridgeDummy {
  private weak var webView: WKWebView?

  init(webView: WKWebView) {
    self.webView = webView
  }

  /// Don't call this directly, it does nothing.
  ///
  /// We use this to generate types that are not covered in exposed interfaces, as a workaround.
  public func __generateTypes__(arg0: EditorIndentBehavior, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let arg0: EditorIndentBehavior
    }

    let message = Message(
      arg0: arg0
    )

    webView?.invoke(path: "webModules.dummy.__generateTypes__", message: message, completion: completion)
  }
}
