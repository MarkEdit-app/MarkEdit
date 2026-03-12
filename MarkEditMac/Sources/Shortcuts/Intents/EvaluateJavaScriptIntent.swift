//
//  EvaluateJavaScriptIntent.swift
//  MarkEditMac
//
//  Created by cyan on 3/14/23.
//

import AppIntents
import MarkEditKit

struct EvaluateJavaScriptIntent: AppIntent {
  static let title: LocalizedStringResource = "Evaluate JavaScript"
  static let description = IntentDescription("Evaluates JavaScript and gets the result on the active document; throws an error if no editor is opened.")

  static var parameterSummary: some ParameterSummary {
    Summary("Evaluate JavaScript with \(\.$content)") {
      \.$callAsync
    }
  }

  @Parameter(title: "Content", inputOptions: String.IntentInputOptions(capitalizationType: .none, multiline: true, autocorrect: false, smartQuotes: false, smartDashes: false))
  var content: String

  @Parameter(title: "Call Async JavaScript", description: "Allows the evaluation to return a Promise object. When enabled, the JavaScript must return a value.", default: false)
  var callAsync: Bool

  @MainActor
  func perform() async throws -> some ReturnsValue<String> {
    guard let currentEditor else {
      throw IntentError.missingDocument
    }

    // We do not directly use the async version of evaluateJavaScript,
    // mainly because that it **sometimes** emits Optional(nil) unwrapping error.
    return try await withCheckedThrowingContinuation { continuation in
      currentEditor.webView.evaluateJavaScript(content, callAsync: callAsync) { value, error in
        // Here we have to deal with this typing hell
        continuation.resume(with: .success(.result(value: String(describing: value ?? error ?? "undefined"))))
      }
    }
  }
}
