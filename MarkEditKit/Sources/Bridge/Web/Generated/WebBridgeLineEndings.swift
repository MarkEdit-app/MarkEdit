//
//  WebBridgeLineEndings.swift
//
//  Generated using https://github.com/microsoft/ts-gyb
//
//  Don't modify this file manually, it's auto generated.
//
//  To make changes, edit template files under /CoreEditor/src/@codegen

import WebKit
import MarkEditCore

@MainActor
public final class WebBridgeLineEndings {
  private weak var webView: WKWebView?

  init(webView: WKWebView) {
    self.webView = webView
  }

  public func getLineEndings() async throws -> LineEndings {
    return try await withCheckedThrowingContinuation { continuation in
      webView?.invoke(path: "webModules.lineEndings.getLineEndings") { result in
        Task { @MainActor in
          continuation.resume(with: result)
        }
      }
    }
  }

  public func setLineEndings(lineEndings: LineEndings, completion: ((Result<Void, WKWebView.InvokeError>) -> Void)? = nil) {
    struct Message: Encodable {
      let lineEndings: LineEndings
    }

    let message = Message(
      lineEndings: lineEndings
    )

    webView?.invoke(path: "webModules.lineEndings.setLineEndings", message: message, completion: completion)
  }
}

public enum LineEndings: Int, Codable {
  /// Unspecified, let CodeMirror do the normalization magic.
  case unspecified = 0
  /// Line Feed, used on macOS and Unix systems.
  case lf = 1
  /// Carriage Return and Line Feed, used on Windows.
  case crlf = 2
  /// Carriage Return, previously used on Classic Mac OS.
  case cr = 3
}
