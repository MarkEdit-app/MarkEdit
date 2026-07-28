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
    let message = BridgeMessage(
      ("arg0", arg0)
    )

    webView?.invoke(path: "webModules.foundationModels.__generateTypes__", message: message, completion: completion)
  }

  public func applyStreamUpdate(streamID: String, response: LanguageModelResponse, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    let message = BridgeMessage(
      ("streamID", streamID),
      ("response", response)
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

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: BridgeFieldKey.self)
    isAvailable = try container.value("isAvailable")
    unavailableReason = try container.value("unavailableReason")
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: BridgeFieldKey.self)
    try container.encode(isAvailable, forKey: "isAvailable")
    try container.encode(unavailableReason, forKey: "unavailableReason")
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

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: BridgeFieldKey.self)
    content = try container.value("content")
    error = try container.value("error")
    done = try container.value("done")
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: BridgeFieldKey.self)
    try container.encode(content, forKey: "content")
    try container.encode(error, forKey: "error")
    try container.encode(done, forKey: "done")
  }
}
