//
//  EditorMessageHandler.swift
//
//  Created by cyan on 12/22/22.
//

import WebKit

/**
 Receive messages sent from the web, execute functions and get back to the web.
 */
public final class EditorMessageHandler: NSObject, Sendable, WKScriptMessageHandlerWithReply {
  private let modules: NativeModules

  public init(modules: NativeModules) {
    self.modules = modules
  }

  public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) async -> (Any?, String?) {
    let reportError: (String) -> (Any?, String?) = { message in
      Logger.assertFail(message)
      return (nil, message)
    }

    guard message.name == "bridge", let body = message.body as? [String: Any] else {
      return reportError("Invalid message payload: \(message.name), \(message.body)")
    }

    guard let moduleName = body["moduleName"] as? String else {
      return reportError("Invalid module name from payload: \(message.body)")
    }

    guard let methodName = body["methodName"] as? String else {
      return reportError("Invalid method name from payload: \(message.body)")
    }

    let moduleMethodPath = "\(moduleName).\(methodName)"
    Logger.log(.debug, "Invoking native method: \(moduleMethodPath)")

    guard let invokeNative = modules[moduleName]?[methodName] else {
      return reportError("Invalid native method path: \(moduleMethodPath)")
    }

    guard let parameters = (body["parameters"] as? String)?.toData() else {
      return reportError("Invalid parameters from native method: \(moduleMethodPath)")
    }

    guard let result = invokeNative(parameters) else {
      return reportError("Missing result from native method: \(moduleMethodPath)")
    }

    switch result {
    case .success(let value):
      return (value, nil)
    case .failure(let error):
      return (nil, error.localizedDescription)
    }
  }
}
