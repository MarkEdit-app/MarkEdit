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

@MainActor
public final class WebBridgeTableOfContents {
  private weak var webView: WKWebView?

  init(webView: WKWebView) {
    self.webView = webView
  }

  public func getTableOfContents() async throws -> [HeadingInfo] {
    guard let webView else {
      throw WKWebView.InvokeError.unexpectedNil
    }

    return try await webView.invoke(path: "webModules.toc.getTableOfContents")
  }

  public func getDocumentOutline(knownRevision: String?) async throws -> DocumentOutline {
    let message = BridgeMessage(
      ("knownRevision", knownRevision)
    )

    guard let webView else {
      throw WKWebView.InvokeError.unexpectedNil
    }

    return try await webView.invoke(path: "webModules.toc.getDocumentOutline", message: message)
  }

  public func selectPreviousSection(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.toc.selectPreviousSection", completion: completion)
  }

  public func selectNextSection(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.toc.selectNextSection", completion: completion)
  }

  public func gotoHeader(headingInfo: HeadingInfo, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    let message = BridgeMessage(
      ("headingInfo", headingInfo)
    )

    webView?.invoke(path: "webModules.toc.gotoHeader", message: message, completion: completion)
  }
}

public struct HeadingInfo: Codable, Sendable {
  public var title: String
  public var level: Int
  public var from: Int
  public var to: Int
  public var selected: Bool
  public var lineNumber: Int

  public init(title: String, level: Int, from: Int, to: Int, selected: Bool, lineNumber: Int) {
    self.title = title
    self.level = level
    self.from = from
    self.to = to
    self.selected = selected
    self.lineNumber = lineNumber
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: BridgeFieldKey.self)
    title = try container.value("title")
    level = try container.value("level")
    from = try container.value("from")
    to = try container.value("to")
    selected = try container.value("selected")
    lineNumber = try container.value("lineNumber")
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: BridgeFieldKey.self)
    try container.encode(title, forKey: "title")
    try container.encode(level, forKey: "level")
    try container.encode(from, forKey: "from")
    try container.encode(to, forKey: "to")
    try container.encode(selected, forKey: "selected")
    try container.encode(lineNumber, forKey: "lineNumber")
  }
}

public struct DocumentOutline: Codable, Sendable {
  public var revision: String
  public var text: String?
  public var headings: [HeadingInfo]

  public init(revision: String, text: String?, headings: [HeadingInfo]) {
    self.revision = revision
    self.text = text
    self.headings = headings
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: BridgeFieldKey.self)
    revision = try container.value("revision")
    text = try container.value("text")
    headings = try container.value("headings")
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: BridgeFieldKey.self)
    try container.encode(revision, forKey: "revision")
    try container.encode(text, forKey: "text")
    try container.encode(headings, forKey: "headings")
  }
}
