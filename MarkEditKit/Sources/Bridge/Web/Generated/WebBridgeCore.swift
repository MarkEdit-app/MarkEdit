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

@MainActor
public final class WebBridgeCore {
  private weak var webView: WKWebView?

  init(webView: WKWebView) {
    self.webView = webView
  }

  public func resetEditor(text: String, selectionRange: SelectionRange?, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let text: String
      let selectionRange: SelectionRange?
    }

    let message = Message(
      text: text,
      selectionRange: selectionRange
    )

    webView?.invoke(path: "webModules.core.resetEditor", message: message, completion: completion)
  }

  public func getEditorState() async throws -> WebBridgeCoreGetEditorStateReturnType {
    guard let webView else {
      throw WKWebView.InvokeError.unexpectedNil
    }

    return try await webView.invoke(path: "webModules.core.getEditorState")
  }

  public func getEditorText() async throws -> String {
    guard let webView else {
      throw WKWebView.InvokeError.unexpectedNil
    }

    return try await webView.invoke(path: "webModules.core.getEditorText")
  }

  public func getReadableContentPair() async throws -> ReadableContentPair {
    guard let webView else {
      throw WKWebView.InvokeError.unexpectedNil
    }

    return try await webView.invoke(path: "webModules.core.getReadableContentPair")
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

  public func performTextDrop(text: String, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let text: String
    }

    let message = Message(
      text: text
    )

    webView?.invoke(path: "webModules.core.performTextDrop", message: message, completion: completion)
  }

  public func handleFocusLost(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.core.handleFocusLost", completion: completion)
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

  public func setHasModalSheet(value: Bool, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let value: Bool
    }

    let message = Message(
      value: value
    )

    webView?.invoke(path: "webModules.core.setHasModalSheet", message: message, completion: completion)
  }
}

public struct WebBridgeCoreGetEditorStateReturnType: Codable, Equatable {
  public var hasFocus: Bool
  public var hasSelection: Bool

  public init(hasFocus: Bool, hasSelection: Bool) {
    self.hasFocus = hasFocus
    self.hasSelection = hasSelection
  }
}

public struct ReadableContentPair: Codable, Equatable {
  public var fullText: ReadableContent
  public var selection: ReadableContent?

  public init(fullText: ReadableContent, selection: ReadableContent?) {
    self.fullText = fullText
    self.selection = selection
  }
}

public struct ReadableContent: Codable, Equatable {
  public var sourceText: String
  public var trimmedText: String
  public var paragraphCount: Int
  public var commentCount: Int

  public init(sourceText: String, trimmedText: String, paragraphCount: Int, commentCount: Int) {
    self.sourceText = sourceText
    self.trimmedText = trimmedText
    self.paragraphCount = paragraphCount
    self.commentCount = commentCount
  }
}

public enum ReplaceGranularity: String, Codable {
  case wholeDocument = "wholeDocument"
  case selection = "selection"
}
