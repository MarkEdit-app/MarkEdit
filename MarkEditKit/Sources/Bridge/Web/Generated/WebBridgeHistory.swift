//
//  WebBridgeHistory.swift
//
//  Generated using https://github.com/microsoft/ts-gyb
//
//  Don't modify this file manually, it's auto generated.
//
//  To make changes, edit template files under /CoreEditor/src/@codegen

import WebKit
import MarkEditCore

@MainActor
public final class WebBridgeHistory {
  private weak var webView: WKWebView?

  init(webView: WKWebView) {
    self.webView = webView
  }

  public func undo(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.history.undo", completion: completion)
  }

  public func redo(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.history.redo", completion: completion)
  }

  public func canUndo() async throws -> Bool {
    return try await withCheckedThrowingContinuation { continuation in
      webView?.invoke(path: "webModules.history.canUndo") {
        continuation.resume(with: $0)
      }
    }
  }

  public func canRedo() async throws -> Bool {
    return try await withCheckedThrowingContinuation { continuation in
      webView?.invoke(path: "webModules.history.canRedo") {
        continuation.resume(with: $0)
      }
    }
  }

  public func markContentClean(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.history.markContentClean", completion: completion)
  }
}
