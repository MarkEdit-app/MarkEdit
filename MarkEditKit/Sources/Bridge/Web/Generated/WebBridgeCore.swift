//
//  WebBridgeCore.swift
//
//  Generated using https://github.com/microsoft/ts-gyb
//
//  Don't modify this file manually, it's auto generated.
//
//  To make changes, edit template files under /CoreEditor/src/@codegen

import WebKit
import MarkEditCore

public final class WebBridgeCore {
  private weak var webView: WKWebView?

  init(webView: WKWebView) {
    self.webView = webView
  }

  public func resetEditor(text: String, revision: String?, revisionMode: Bool, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let text: String
      let revision: String?
      let revisionMode: Bool
    }

    let message = Message(
      text: text,
      revision: revision,
      revisionMode: revisionMode
    )

    webView?.invoke(path: "webModules.core.resetEditor", message: message, completion: completion)
  }

  public func clearEditor(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.core.clearEditor", completion: completion)
  }

  @MainActor
  public func getEditorText() async throws -> String {
    return try await withCheckedThrowingContinuation { continuation in
      webView?.invoke(path: "webModules.core.getEditorText") {
        continuation.resume(with: $0)
      }
    }
  }

  public func insertText(text: String, from: Int, to: Int, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let text: String
      let from: Int
      let to: Int
    }

    let message = Message(
      text: text,
      from: from,
      to: to
    )

    webView?.invoke(path: "webModules.core.insertText", message: message, completion: completion)
  }

  public func replaceText(text: String, granularity: ReplaceGranularity, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let text: String
      let granularity: ReplaceGranularity
    }

    let message = Message(
      text: text,
      granularity: granularity
    )

    webView?.invoke(path: "webModules.core.replaceText", message: message, completion: completion)
  }

  public func handleFocusLost(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.core.handleFocusLost", completion: completion)
  }

  public func handleMouseEntered(clientX: Double, clientY: Double, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let clientX: Double
      let clientY: Double
    }

    let message = Message(
      clientX: clientX,
      clientY: clientY
    )

    webView?.invoke(path: "webModules.core.handleMouseEntered", message: message, completion: completion)
  }

  public func handleMouseExited(clientX: Double, clientY: Double, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let clientX: Double
      let clientY: Double
    }

    let message = Message(
      clientX: clientX,
      clientY: clientY
    )

    webView?.invoke(path: "webModules.core.handleMouseExited", message: message, completion: completion)
  }
}

public enum ReplaceGranularity: String, Codable {
  case wholeDocument = "wholeDocument"
  case selection = "selection"
}
