//
//  EditorMessageHandler.swift
//
//  Created by cyan on 12/22/22.
//

import WebKit

/**
 Receive messages sent from the web, execute functions and get back to the web.
 */
public final class EditorMessageHandler: NSObject, WKScriptMessageHandlerWithReply {
  private let modules: NativeModules

  public init(modules: NativeModules) {
    self.modules = modules
  }

  @MainActor
  public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) async -> (Any?, String?) {
    let assertFail: (String) -> (Any?, String?) = { message in
      Logger.assertFail(message)
      return (nil, message)
    }

    guard message.name == "bridge", let body = message.body as? [String: Any] else {
      return assertFail("Invalid message payload")
    }

    guard let moduleName = body["moduleName"] as? String else {
      return assertFail("Invalid module name")
    }

    guard let methodName = body["methodName"] as? String else {
      return assertFail("Invalid method name")
    }

    guard let invokeNative = modules[moduleName]?[methodName] else {
      return assertFail("Invalid native method")
    }

    guard let parameters = (body["parameters"] as? String)?.toData() else {
      return assertFail("Invalid parameters")
    }

    guard let result = invokeNative(parameters) else {
      return assertFail("Missing result from native method: \(methodName)")
    }

    Logger.log(.debug, "Invoked native: \(moduleName).\(methodName)")
    switch result {
    case .success(let value):
      return (value, nil)
    case .failure(let error):
      return (nil, error.localizedDescription)
    }
  }
}
