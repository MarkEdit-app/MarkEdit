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

  public func resetEditor(text: String, selectionRange: SelectionRange?, documentChanged: Bool) async throws -> Bool {
    let message = BridgeMessage(
      ("text", text),
      ("selectionRange", selectionRange),
      ("documentChanged", documentChanged)
    )

    guard let webView else {
      throw WKWebView.InvokeError.unexpectedNil
    }

    return try await webView.invoke(path: "webModules.core.resetEditor", message: message, callAsync: true)
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
    let message = BridgeMessage(
      ("text", text),
      ("from", from),
      ("to", to)
    )

    webView?.invoke(path: "webModules.core.insertText", message: message, completion: completion)
  }

  public func replaceText(text: String, granularity: ReplaceGranularity, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    let message = BridgeMessage(
      ("text", text),
      ("granularity", granularity)
    )

    webView?.invoke(path: "webModules.core.replaceText", message: message, completion: completion)
  }

  public func performTextDrop(text: String, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    let message = BridgeMessage(
      ("text", text)
    )

    webView?.invoke(path: "webModules.core.performTextDrop", message: message, completion: completion)
  }

  public func handleFocusLost(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.core.handleFocusLost", completion: completion)
  }

  public func handleMouseExited(clientX: Double, clientY: Double, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    let message = BridgeMessage(
      ("clientX", clientX),
      ("clientY", clientY)
    )

    webView?.invoke(path: "webModules.core.handleMouseExited", message: message, completion: completion)
  }

  public func setHasModalSheet(value: Bool, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    let message = BridgeMessage(
      ("value", value)
    )

    webView?.invoke(path: "webModules.core.setHasModalSheet", message: message, completion: completion)
  }
}

public struct WebBridgeCoreGetEditorStateReturnType: Codable {
  public var hasFocus: Bool
  public var hasSelection: Bool

  public init(hasFocus: Bool, hasSelection: Bool) {
    self.hasFocus = hasFocus
    self.hasSelection = hasSelection
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: BridgeFieldKey.self)
    hasFocus = try container.value("hasFocus")
    hasSelection = try container.value("hasSelection")
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: BridgeFieldKey.self)
    try container.encode(hasFocus, forKey: "hasFocus")
    try container.encode(hasSelection, forKey: "hasSelection")
  }
}

public struct ReadableContentPair: Codable {
  public var fullText: ReadableContent
  public var selection: ReadableContent?

  public init(fullText: ReadableContent, selection: ReadableContent?) {
    self.fullText = fullText
    self.selection = selection
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: BridgeFieldKey.self)
    fullText = try container.value("fullText")
    selection = try container.value("selection")
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: BridgeFieldKey.self)
    try container.encode(fullText, forKey: "fullText")
    try container.encode(selection, forKey: "selection")
  }
}

public struct ReadableContent: Codable {
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

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: BridgeFieldKey.self)
    sourceText = try container.value("sourceText")
    trimmedText = try container.value("trimmedText")
    paragraphCount = try container.value("paragraphCount")
    commentCount = try container.value("commentCount")
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: BridgeFieldKey.self)
    try container.encode(sourceText, forKey: "sourceText")
    try container.encode(trimmedText, forKey: "trimmedText")
    try container.encode(paragraphCount, forKey: "paragraphCount")
    try container.encode(commentCount, forKey: "commentCount")
  }
}

public enum ReplaceGranularity: String, Codable {
  case wholeDocument = "wholeDocument"
  case selection = "selection"
}
