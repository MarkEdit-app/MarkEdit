//
//  WebBridgeSearch.swift
//
//  Generated using https://github.com/microsoft/ts-gyb
//
//  Don't modify this file manually, it's auto generated.
//
//  To make changes, edit template files under /CoreEditor/src/@codegen

import WebKit
import MarkEditCore

@MainActor
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

  public func updateQuery(options: SearchOptions, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let options: SearchOptions
    }

    let message = Message(
      options: options
    )

    webView?.invoke(path: "webModules.search.updateQuery", message: message, completion: completion)
  }

  public func updateHasSelection(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.search.updateHasSelection", completion: completion)
  }

  public func performOperation(operation: SearchOperation, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let operation: SearchOperation
    }

    let message = Message(
      operation: operation
    )

    webView?.invoke(path: "webModules.search.performOperation", message: message, completion: completion)
  }

  public func findNext(search: String) async throws -> Bool {
    struct Message: Encodable {
      let search: String
    }

    let message = Message(
      search: search
    )

    return try await withCheckedThrowingContinuation { continuation in
      webView?.invoke(path: "webModules.search.findNext", message: message) { result in
        Task { @MainActor in
          continuation.resume(with: result)
        }
      }
    }
  }

  public func findPrevious(search: String) async throws -> Bool {
    struct Message: Encodable {
      let search: String
    }

    let message = Message(
      search: search
    )

    return try await withCheckedThrowingContinuation { continuation in
      webView?.invoke(path: "webModules.search.findPrevious", message: message) { result in
        Task { @MainActor in
          continuation.resume(with: result)
        }
      }
    }
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

  public func selectNextOccurrence() async throws -> Bool {
    return try await withCheckedThrowingContinuation { continuation in
      webView?.invoke(path: "webModules.search.selectNextOccurrence") { result in
        Task { @MainActor in
          continuation.resume(with: result)
        }
      }
    }
  }

  public func getCounterInfo() async throws -> SearchCounterInfo {
    return try await withCheckedThrowingContinuation { continuation in
      webView?.invoke(path: "webModules.search.getCounterInfo") { result in
        Task { @MainActor in
          continuation.resume(with: result)
        }
      }
    }
  }
}

public struct SearchOptions: Codable {
  public var search: String
  public var caseSensitive: Bool
  public var diacriticInsensitive: Bool
  public var wholeWord: Bool
  public var literal: Bool
  public var regexp: Bool
  public var refocus: Bool
  public var replace: String?

  public init(search: String, caseSensitive: Bool, diacriticInsensitive: Bool, wholeWord: Bool, literal: Bool, regexp: Bool, refocus: Bool, replace: String?) {
    self.search = search
    self.caseSensitive = caseSensitive
    self.diacriticInsensitive = diacriticInsensitive
    self.wholeWord = wholeWord
    self.literal = literal
    self.regexp = regexp
    self.refocus = refocus
    self.replace = replace
  }
}

public enum SearchOperation: String, Codable {
  case selectAll = "selectAll"
  case selectAllInSelection = "selectAllInSelection"
  case replaceAll = "replaceAll"
  case replaceAllInSelection = "replaceAllInSelection"
}

/// Info to show text like "1 of 3".
public struct SearchCounterInfo: Codable {
  /// Total number of matched items
  public var numberOfItems: Int
  /// Index for the selected item, zero-based
  public var currentIndex: Int

  public init(numberOfItems: Int, currentIndex: Int) {
    self.numberOfItems = numberOfItems
    self.currentIndex = currentIndex
  }
}
