//
//  WKWebView+Extension.swift
//
//  Created by cyan on 12/22/22.
//

import WebKit
import MarkEditCore

/**
 WKWebView extension to show inspector programmatically.
 */

public extension WKWebView {
  func evaluateJavaScript(
    _ script: String,
    callAsync: Bool,
    completionHandler: (@MainActor @Sendable (Any?, (any Error)?) -> Void)? = nil
  ) {
    if callAsync {
      callAsyncJavaScript(script, in: nil, in: .page) { result in
        switch result {
        case .success(let value):
          completionHandler?(value, nil)
        case .failure(let error):
          completionHandler?(nil, error)
        }
      }
    } else {
      evaluateJavaScript(script, completionHandler: completionHandler)
    }
  }

  func showInspector() {
    let objectSel = sel_getUid("_inspector")
    let methodSel = sel_getUid("show")

    guard responds(to: objectSel), let inspector = perform(objectSel)?.takeUnretainedValue() else {
      return Logger.assertFail("Missing object \"_inspector\" in: \(self)")
    }

    guard inspector.responds(to: methodSel) else {
      return Logger.assertFail("Missing method \"show\" in: \(inspector)")
    }

    _ = inspector.perform(methodSel)
  }
}

/**
 WKWebView extension to encode and decode messages.
 */
extension WKWebView {
  @frozen public enum InvokeError: Error {
    case unexpectedNil
    case decodeError
    case evaluateError(path: String, error: Error?)
  }

  typealias VoidCompletion = (Result<Void, InvokeError>) -> Void
}

extension WKWebView {
  func invoke(path: String, message: Encodable = Message(), completion: VoidCompletion? = nil) {
    let script = invokeScript(path: path, message: message)
    evaluateJavaScript(script) { _, error in
      if let error {
        Logger.log(.error, error.localizedDescription)
        completion?(.failure(.evaluateError(path: path, error: error)))
      } else {
        completion?(.success(()))
      }
    }
  }

  func invoke<SuccessResult: Decodable>(path: String, message: Encodable = Message()) async throws -> SuccessResult {
    let script = invokeScript(path: path, message: message)

    let value: Any?
    do {
      value = try await evaluateJavaScript(script)
    } catch {
      Logger.log(.error, error.localizedDescription)
      throw InvokeError.evaluateError(path: path, error: error)
    }

    guard let value, !(value is NSNull) else {
      throw InvokeError.unexpectedNil
    }

    // Primitive types
    if let value = value as? SuccessResult {
      return value
    }

    do {
      // JSON encoded types
      let data = try JSONSerialization.data(withJSONObject: value, options: .fragmentsAllowed)
      return try JSONDecoder().decode(SuccessResult.self, from: data)
    } catch {
      Logger.log(.error, error.localizedDescription)
      throw InvokeError.decodeError
    }
  }
}

// MARK: - Private

private extension WKWebView {
  struct Message: Encodable {
    // Empty message used for zero parameter functions
  }

  func invokeScript(path: String, message: Encodable) -> String {
    let module = path.components(separatedBy: ".").first ?? "undefined"
    return "typeof \(module) === 'object' ? \(path)(\(message.jsonEncoded)) : undefined"
  }
}
