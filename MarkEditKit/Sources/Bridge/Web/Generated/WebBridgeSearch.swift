//
//  WebBridgeSearch.swift
//
//  Generated using https://github.com/microsoft/ts-gyb
//
//  Don't modify this file manually, it's auto generated.
//
//  To make changes, edit template files under /CoreEditor/src/@codegen

import WebKit

public final class WebBridgeSearch {
  private weak var webView: WKWebView?

  init(webView: WKWebView) {
    self.webView = webView
  }

  public func setState(enabled: Bool, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let enabled: Bool
    }

    let message = Message(
      enabled: enabled
    )

    webView?.invoke(path: "webModules.search.setState", message: message, completion: completion)
  }

  @MainActor public func updateQuery(options: SearchOptions) async throws -> Int {
    struct Message: Encodable {
      let options: SearchOptions
    }

    let message = Message(
      options: options
    )

    return try await withCheckedThrowingContinuation { continuation in
      webView?.invoke(path: "webModules.search.updateQuery", message: message) {
        continuation.resume(with: $0)
      }
    }
  }

  public func findNext(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.search.findNext", completion: completion)
  }

  public func findPrevious(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.search.findPrevious", completion: completion)
  }

  public func replaceNext(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.search.replaceNext", completion: completion)
  }

  public func replaceAll(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.search.replaceAll", completion: completion)
  }

  public func selectAllOccurrences(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.search.selectAllOccurrences", completion: completion)
  }

  @MainActor public func numberOfMatches() async throws -> Int {
    return try await withCheckedThrowingContinuation { continuation in
      webView?.invoke(path: "webModules.search.numberOfMatches") {
        continuation.resume(with: $0)
      }
    }
  }
}

public struct SearchOptions: Codable {
  public var search: String
  public var caseSensitive: Bool
  public var literal: Bool
  public var regexp: Bool
  public var wholeWord: Bool
  public var replace: String?

  public init(search: String, caseSensitive: Bool, literal: Bool, regexp: Bool, wholeWord: Bool, replace: String?) {
    self.search = search
    self.caseSensitive = caseSensitive
    self.literal = literal
    self.regexp = regexp
    self.wholeWord = wholeWord
    self.replace = replace
  }
}
