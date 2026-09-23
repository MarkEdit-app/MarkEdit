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

@MainActor
public final class WebBridgeSelection {
  private weak var webView: WKWebView?

  init(webView: WKWebView) {
    self.webView = webView
  }

  public func selectWholeDocument(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.selection.selectWholeDocument", completion: completion)
  }

  public func getText() async throws -> String {
    guard let webView else {
      throw WKWebView.InvokeError.unexpectedNil
    }

    return try await webView.invoke(path: "webModules.selection.getText")
  }

  public func getRect(pos: Int) async throws -> WebRect? {
    let message = BridgeMessage(
      ("pos", pos)
    )

    guard let webView else {
      throw WKWebView.InvokeError.unexpectedNil
    }

    return try await webView.invoke(path: "webModules.selection.getRect", message: message)
  }

  public func scrollToSelection(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.selection.scrollToSelection", completion: completion)
  }

  public func gotoLine(lineNumber: Int, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    let message = BridgeMessage(
      ("lineNumber", lineNumber)
    )

    webView?.invoke(path: "webModules.selection.gotoLine", message: message, completion: completion)
  }

  public func refreshEditFocus(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.selection.refreshEditFocus", completion: completion)
  }

  public func navigateGoBack(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.selection.navigateGoBack", completion: completion)
  }
}

/// "CGRect-fashion" rect.
public struct WebRect: Codable, Sendable {
  public var x: Double
  public var y: Double
  public var width: Double
  public var height: Double

  public init(x: Double, y: Double, width: Double, height: Double) {
    self.x = x
    self.y = y
    self.width = width
    self.height = height
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: BridgeFieldKey.self)
    x = try container.value("x")
    y = try container.value("y")
    width = try container.value("width")
    height = try container.value("height")
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: BridgeFieldKey.self)
    try container.encode(x, forKey: "x")
    try container.encode(y, forKey: "y")
    try container.encode(width, forKey: "width")
    try container.encode(height, forKey: "height")
  }
}
