//
//  WebBridgeFoundationModels.swift
//
//  Generated using https://github.com/microsoft/ts-gyb
//
//  Don't modify this file manually, it's auto generated.
//
//  To make changes, edit template files under /CoreEditor/src/@codegen

import WebKit
import MarkEditCore

@MainActor
public final class WebBridgeFoundationModels {
  private weak var webView: WKWebView?

  init(webView: WKWebView) {
    self.webView = webView
  }

  /// Don't call this directly, it does nothing.
  public func __generateTypes__(arg0: LanguageModelAvailability, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let arg0: LanguageModelAvailability
    }

    let message = Message(
      arg0: arg0
    )

    webView?.invoke(path: "webModules.foundationModels.__generateTypes__", message: message, completion: completion)
  }

  public func applyStreamUpdate(streamID: String, response: LanguageModelResponse, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let streamID: String
      let response: LanguageModelResponse
    }

    let message = Message(
      streamID: streamID,
      response: response
    )

    webView?.invoke(path: "webModules.foundationModels.applyStreamUpdate", message: message, completion: completion)
  }
}

public struct LanguageModelAvailability: Codable {
  public var isAvailable: Bool
  public var unavailableReason: String?

  public init(isAvailable: Bool, unavailableReason: String?) {
    self.isAvailable = isAvailable
    self.unavailableReason = unavailableReason
  }
}

public struct LanguageModelResponse: Codable {
  public var content: String?
  public var error: String?
  public var done: Bool

  public init(content: String?, error: String?, done: Bool) {
    self.content = content
    self.error = error
    self.done = done
  }
}
