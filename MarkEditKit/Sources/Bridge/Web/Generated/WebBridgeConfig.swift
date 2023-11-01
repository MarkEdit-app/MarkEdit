//
//  WebBridgeConfig.swift
//
//  Generated using https://github.com/microsoft/ts-gyb
//
//  Don't modify this file manually, it's auto generated.
//
//  To make changes, edit template files under /CoreEditor/src/@codegen

import WebKit
import MarkEditCore

public final class WebBridgeConfig {
  private weak var webView: WKWebView?

  init(webView: WKWebView) {
    self.webView = webView
  }

  public func setTheme(name: String, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let name: String
    }

    let message = Message(
      name: name
    )

    webView?.invoke(path: "webModules.config.setTheme", message: message, completion: completion)
  }

  public func setFontFace(fontFace: WebFontFace, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let fontFace: WebFontFace
    }

    let message = Message(
      fontFace: fontFace
    )

    webView?.invoke(path: "webModules.config.setFontFace", message: message, completion: completion)
  }

  public func setFontSize(fontSize: Double, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let fontSize: Double
    }

    let message = Message(
      fontSize: fontSize
    )

    webView?.invoke(path: "webModules.config.setFontSize", message: message, completion: completion)
  }

  public func setShowLineNumbers(enabled: Bool, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let enabled: Bool
    }

    let message = Message(
      enabled: enabled
    )

    webView?.invoke(path: "webModules.config.setShowLineNumbers", message: message, completion: completion)
  }

  public func setShowActiveLineIndicator(enabled: Bool, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let enabled: Bool
    }

    let message = Message(
      enabled: enabled
    )

    webView?.invoke(path: "webModules.config.setShowActiveLineIndicator", message: message, completion: completion)
  }

  public func setInvisiblesBehavior(behavior: EditorInvisiblesBehavior, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let behavior: EditorInvisiblesBehavior
    }

    let message = Message(
      behavior: behavior
    )

    webView?.invoke(path: "webModules.config.setInvisiblesBehavior", message: message, completion: completion)
  }

  public func setReadOnlyMode(enabled: Bool, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let enabled: Bool
    }

    let message = Message(
      enabled: enabled
    )

    webView?.invoke(path: "webModules.config.setReadOnlyMode", message: message, completion: completion)
  }

  public func setTypewriterMode(enabled: Bool, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let enabled: Bool
    }

    let message = Message(
      enabled: enabled
    )

    webView?.invoke(path: "webModules.config.setTypewriterMode", message: message, completion: completion)
  }

  public func setFocusMode(enabled: Bool, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let enabled: Bool
    }

    let message = Message(
      enabled: enabled
    )

    webView?.invoke(path: "webModules.config.setFocusMode", message: message, completion: completion)
  }

  public func setLineWrapping(enabled: Bool, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let enabled: Bool
    }

    let message = Message(
      enabled: enabled
    )

    webView?.invoke(path: "webModules.config.setLineWrapping", message: message, completion: completion)
  }

  public func setLineHeight(lineHeight: Double, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let lineHeight: Double
    }

    let message = Message(
      lineHeight: lineHeight
    )

    webView?.invoke(path: "webModules.config.setLineHeight", message: message, completion: completion)
  }

  public func setDefaultLineBreak(lineBreak: String?, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let lineBreak: String?
    }

    let message = Message(
      lineBreak: lineBreak
    )

    webView?.invoke(path: "webModules.config.setDefaultLineBreak", message: message, completion: completion)
  }

  public func setTabKeyBehavior(behavior: TabKeyBehavior, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let behavior: TabKeyBehavior
    }

    let message = Message(
      behavior: behavior
    )

    webView?.invoke(path: "webModules.config.setTabKeyBehavior", message: message, completion: completion)
  }

  public func setIndentUnit(unit: String, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let unit: String
    }

    let message = Message(
      unit: unit
    )

    webView?.invoke(path: "webModules.config.setIndentUnit", message: message, completion: completion)
  }

  public func setSuggestWhileTyping(enabled: Bool, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let enabled: Bool
    }

    let message = Message(
      enabled: enabled
    )

    webView?.invoke(path: "webModules.config.setSuggestWhileTyping", message: message, completion: completion)
  }
}

public enum TabKeyBehavior: Int, Codable {
  case insertTab = 0
  case insertTwoSpaces = 1
  case insertFourSpaces = 2
  case indentMore = 3
}
