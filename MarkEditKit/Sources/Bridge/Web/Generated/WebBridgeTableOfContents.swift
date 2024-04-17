//
//  WebBridgeTableOfContents.swift
//
//  Generated using https://github.com/microsoft/ts-gyb
//
//  Don't modify this file manually, it's auto generated.
//
//  To make changes, edit template files under /CoreEditor/src/@codegen

import WebKit
import MarkEditCore

public final class WebBridgeTableOfContents {
  private weak var webView: WKWebView?

  init(webView: WKWebView) {
    self.webView = webView
  }

  @MainActor
  public func getTableOfContents() async throws -> [HeadingInfo] {
    return try await withCheckedThrowingContinuation { continuation in
      webView?.invoke(path: "webModules.toc.getTableOfContents") {
        continuation.resume(with: $0)
      }
    }
  }

  @MainActor
  public func selectPreviousSection(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.toc.selectPreviousSection", completion: completion)
  }

  @MainActor
  public func selectNextSection(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.toc.selectNextSection", completion: completion)
  }

  @MainActor
  public func gotoHeader(headingInfo: HeadingInfo, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let headingInfo: HeadingInfo
    }

    let message = Message(
      headingInfo: headingInfo
    )

    webView?.invoke(path: "webModules.toc.gotoHeader", message: message, completion: completion)
  }
}

public struct HeadingInfo: Codable {
  public var title: String
  public var level: Int
  public var from: Int
  public var to: Int
  public var selected: Bool

  public init(title: String, level: Int, from: Int, to: Int, selected: Bool) {
    self.title = title
    self.level = level
    self.from = from
    self.to = to
    self.selected = selected
  }
}
