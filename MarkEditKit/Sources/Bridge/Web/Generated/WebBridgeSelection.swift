//
//  WebBridgeSelection.swift
//
//  Generated using https://github.com/microsoft/ts-gyb
//
//  Don't modify this file manually, it's auto generated.
//
//  To make changes, edit template files under /CoreEditor/src/@codegen

import WebKit
import MarkEditCore

public final class WebBridgeSelection {
  private weak var webView: WKWebView?

  init(webView: WKWebView) {
    self.webView = webView
  }

  public func selectAll(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.selection.selectAll", completion: completion)
  }

  @MainActor
  public func getText() async throws -> String {
    return try await withCheckedThrowingContinuation { continuation in
      webView?.invoke(path: "webModules.selection.getText") {
        continuation.resume(with: $0)
      }
    }
  }

  @MainActor
  public func getRect(pos: Int) async throws -> JSRect? {
    struct Message: Encodable {
      let pos: Int
    }

    let message = Message(
      pos: pos
    )

    return try await withCheckedThrowingContinuation { continuation in
      webView?.invoke(path: "webModules.selection.getRect", message: message) {
        continuation.resume(with: $0)
      }
    }
  }

  public func scrollToSelection(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.selection.scrollToSelection", completion: completion)
  }

  public func gotoLine(lineNumber: Int, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let lineNumber: Int
    }

    let message = Message(
      lineNumber: lineNumber
    )

    webView?.invoke(path: "webModules.selection.gotoLine", message: message, completion: completion)
  }
}
