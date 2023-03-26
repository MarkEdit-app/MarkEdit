//
//  WebBridgeFormat.swift
//
//  Generated using https://github.com/microsoft/ts-gyb
//
//  Don't modify this file manually, it's auto generated.
//
//  To make changes, edit template files under /CoreEditor/src/@codegen

import WebKit
import MarkEditCore

public final class WebBridgeFormat {
  private weak var webView: WKWebView?

  init(webView: WKWebView) {
    self.webView = webView
  }

  public func toggleBold(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.format.toggleBold", completion: completion)
  }

  public func toggleItalic(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.format.toggleItalic", completion: completion)
  }

  public func toggleStrikethrough(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.format.toggleStrikethrough", completion: completion)
  }

  public func toggleHeading(level: Int, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let level: Int
    }

    let message = Message(
      level: level
    )

    webView?.invoke(path: "webModules.format.toggleHeading", message: message, completion: completion)
  }

  public func toggleBullet(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.format.toggleBullet", completion: completion)
  }

  public func toggleNumbering(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.format.toggleNumbering", completion: completion)
  }

  public func toggleTodo(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.format.toggleTodo", completion: completion)
  }

  public func toggleBlockquote(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.format.toggleBlockquote", completion: completion)
  }

  public func toggleInlineCode(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.format.toggleInlineCode", completion: completion)
  }

  public func toggleInlineMath(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.format.toggleInlineMath", completion: completion)
  }

  public func insertCodeBlock(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.format.insertCodeBlock", completion: completion)
  }

  public func insertMathBlock(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.format.insertMathBlock", completion: completion)
  }

  public func insertHorizontalRule(completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    webView?.invoke(path: "webModules.format.insertHorizontalRule", completion: completion)
  }

  public func insertHyperLink(title: String, url: String, prefix: String?, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let title: String
      let url: String
      let prefix: String?
    }

    let message = Message(
      title: title,
      url: url,
      prefix: prefix
    )

    webView?.invoke(path: "webModules.format.insertHyperLink", message: message, completion: completion)
  }

  public func insertTable(columnName: String, itemName: String, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let columnName: String
      let itemName: String
    }

    let message = Message(
      columnName: columnName,
      itemName: itemName
    )

    webView?.invoke(path: "webModules.format.insertTable", message: message, completion: completion)
  }

  public func formatContent(insertFinalNewline: Bool, trimTrailingWhitespace: Bool, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let insertFinalNewline: Bool
      let trimTrailingWhitespace: Bool
    }

    let message = Message(
      insertFinalNewline: insertFinalNewline,
      trimTrailingWhitespace: trimTrailingWhitespace
    )

    webView?.invoke(path: "webModules.format.formatContent", message: message, completion: completion)
  }

  public func performEditCommand(command: EditCommand, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let command: EditCommand
    }

    let message = Message(
      command: command
    )

    webView?.invoke(path: "webModules.format.performEditCommand", message: message, completion: completion)
  }
}

public enum EditCommand: String, Codable {
  case indentLess = "indentLess"
  case indentMore = "indentMore"
  case selectLine = "selectLine"
  case moveLineUp = "moveLineUp"
  case moveLineDown = "moveLineDown"
  case copyLineUp = "copyLineUp"
  case copyLineDown = "copyLineDown"
  case toggleLineComment = "toggleLineComment"
  case toggleBlockComment = "toggleBlockComment"
}
