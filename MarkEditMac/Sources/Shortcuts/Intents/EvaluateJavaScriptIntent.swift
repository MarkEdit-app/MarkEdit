//
//  EvaluateJavaScriptIntent.swift
//  MarkEditMac
//
//  Created by cyan on 3/14/23.
//

import AppIntents

struct EvaluateJavaScriptIntent: AppIntent {
  static let title: LocalizedStringResource = "Evaluate JavaScript"
  static let description = IntentDescription("Evaluates JavaScript and gets the result on the active document; throws an error if no editor is opened.")
  static var parameterSummary: some ParameterSummary {
    Summary("Evaluate JavaScript with \(\.$content)")
  }

  @Parameter(title: "Content", inputOptions: String.IntentInputOptions(capitalizationType: .none, multiline: true, autocorrect: false, smartQuotes: false, smartDashes: false))
  var content: String

  @MainActor
  func perform() async throws -> some ReturnsValue<String> {
    guard let currentEditor else {
      throw IntentError.missingDocument
    }

    // We do not directly use the async version of evaluateJavaScript,
    // mainly because that it **sometimes** emits Optional(nil) unwrapping error.
    return try await withCheckedThrowingContinuation { continuation in
      currentEditor.webView.evaluateJavaScript(content) { value, error in
        // Here we have to deal with this typing hell
        continuation.resume(with: .success(.result(value: String(describing: value ?? error ?? "undefined"))))
      }
    }
  }
}
