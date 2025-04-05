//
//  Error+Scripting.swift
//  MarkEdit
//
//  Created by Stephen Kaplan on 4/4/25.
//

enum ScriptError: Error {
  case missingInput(message: String)
  case noActiveEditor
  case jsEvalError(jsError: NSError)

  var code: Int {
    switch self {
    case .missingInput:
      return NSRequiredArgumentsMissingScriptError
    case .noActiveEditor:
      return -3
    case .jsEvalError:
      return -1702
    }
  }
}

extension ScriptError: LocalizedError {
  func localizedDescription() -> String {
    switch self {
    case .missingInput(message: let message):
      return message
    case .noActiveEditor:
      return "No active editor."
    case .jsEvalError(jsError: let error):
      if let lineNumber = error.userInfo["WKJavaScriptExceptionLineNumber"],
         let columnNumber = error.userInfo["WKJavaScriptExceptionColumnNumber"],
         let errorMessage = error.userInfo["WKJavaScriptExceptionMessage"] {
        return "Line \(lineNumber), column \(columnNumber): \(errorMessage)"
      } else {
        return "JavaScript evaluation failed for an unknown reason."
      }
    }
  }
}
