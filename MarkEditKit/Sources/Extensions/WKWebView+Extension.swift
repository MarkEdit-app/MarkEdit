//
//  WKWebView+Extension.swift
//
//  Created by cyan on 12/22/22.
//

import WebKit
import MarkEditCore

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
  typealias Completion<SuccessResult: Decodable> = (Result<SuccessResult, InvokeError>) -> Void
}

extension WKWebView {
  func invoke(path: String, message: Encodable = Message(), completion: VoidCompletion? = nil) {
    invoke(path: path, message: message) { (result: Result<Any?, InvokeError>) in
      completion?(result.map { _ in () })
    }
  }

  func invoke<SuccessResult: Decodable>(path: String, message: Encodable = Message(), completion: Completion<SuccessResult>? = nil) {
    invoke(path: path, message: message) { (result: Result<Any?, InvokeError>) in
      completion?(result.flatMap { value in
        guard let value, !(value is NSNull) else {
          return .failure(.unexpectedNil)
        }

        // Primitive types
        if let value = value as? SuccessResult {
          return .success(value)
        }

        do {
          // JSON encoded types
          let data = try JSONSerialization.data(withJSONObject: value, options: .fragmentsAllowed)
          let decoded = try JSONDecoder().decode(SuccessResult.self, from: data)
          return .success(decoded)
        } catch {
          Logger.log(.error, error.localizedDescription)
          return .failure(.decodeError)
        }
      })
    }
  }
}

// MARK: - Private

private extension WKWebView {
  struct Message: Encodable {
    // Empty message used for zero parameter functions
  }

  func invoke(path: String, message: Encodable, completion: ((Result<Any?, InvokeError>) -> Void)? = nil) {
    let module = path.components(separatedBy: ".").first ?? "undefined"
    let script = "typeof \(module) === 'object' ? \(path)(\(message.jsonEncoded)) : undefined"
    evaluateJavaScript(script) { result, error in
      if let error {
        Logger.log(.error, error.localizedDescription)
        completion?(.failure(.evaluateError(path: path, error: error)))
      } else {
        completion?(.success(result))
      }
    }
  }
}
