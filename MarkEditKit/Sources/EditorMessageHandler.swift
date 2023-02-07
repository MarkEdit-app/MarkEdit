//
//  EditorMessageHandler.swift
//
//  Created by cyan on 12/22/22.
//

import WebKit

/**
 Receive messages sent from the web, execute functions and get back to the web.
 */
public final class EditorMessageHandler: NSObject, WKScriptMessageHandler {
  private let modules: NativeModules
  private let webViewProvider: (() -> WKWebView?)

  public init(modules: NativeModules, webViewProvider: @escaping (() -> WKWebView?)) {
    self.modules = modules
    self.webViewProvider = webViewProvider
  }

  public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    guard message.name == "bridge", let body = message.body as? [String: Any] else {
      Logger.assertFail("Invalid message payload")
      return
    }

    guard let moduleName = body["moduleName"] as? String else {
      Logger.assertFail("Invalid module name")
      return
    }

    guard let methodName = body["methodName"] as? String else {
      Logger.assertFail("Invalid method name")
      return
    }

    guard let invokeNative = modules[moduleName]?[methodName] else {
      Logger.assertFail("Invalid native method")
      return
    }

    guard let parameters = (body["parameters"] as? String)?.toData() else {
      Logger.assertFail("Invalid parameters")
      return
    }

    guard let messageID = body["id"] as? String else {
      Logger.assertFail("Invalid message id")
      return
    }

    Task {
      Logger.log(.debug, "Invoke native: \(moduleName).\(methodName)")
      if let result = await invokeNative(parameters) {
        reply(id: messageID, result: result)
      }
    }
  }
}

// MARK: - Private

private extension EditorMessageHandler {
  /// Reply to a message sent by JavaScript
  func reply(id: String, result: Result<Encodable?, Error>) {
    guard let webView = webViewProvider() else {
      Logger.log(.error, "Missing WebView to proceed")
      return
    }

    struct NativeReply: Encodable {
      let id: String
      let result: AnyEncodable?
      let error: String?
    }

    if case .failure(let error) = result {
      Logger.assertFail(error.localizedDescription)
    }

    let reply: NativeReply
    switch result {
    case .success(let value):
      if let value = value {
        reply = NativeReply(id: id, result: AnyEncodable(value: value), error: nil)
      } else {
        reply = NativeReply(id: id, result: nil, error: nil)
      }
    case .failure(let error):
      reply = NativeReply(id: id, result: nil, error: error.localizedDescription)
    }

    DispatchQueue.onMainThread {
      webView.invoke(path: "window.handleNativeReply", message: reply)
    }
  }
}

/// Encodable wrapper for generics
///
/// https://www.dabby.dev/article/2019-04-25-any-encodable
private struct AnyEncodable: Encodable {
  let value: Encodable

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try value.encode(to: &container)
  }
}

private extension Encodable {
  func encode(to container: inout SingleValueEncodingContainer) throws {
    try container.encode(self)
  }
}
