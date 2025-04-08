//
//  Error+Scripting.swift
//  MarkEditMac
//
//  Created by Stephen Kaplan on 4/4/25.
//

import Foundation

enum ScriptingError: Error, LocalizedError {
  case missingCommand
  case missingArgument(_ name: String)
  case editorNotFound(_ documentName: String)
  case jsEvaluationError(_ error: NSError)

  var code: Int {
    switch self {
    case .missingCommand:
      return NSCannotCreateScriptCommandError
    case .missingArgument:
      return NSArgumentEvaluationScriptError
    case .editorNotFound:
      return NSReceiverEvaluationScriptError
    case .jsEvaluationError(_: let error):
      return error.code // WKError.javaScriptExceptionOccurred -- 4
    }
  }

  func localizedDescription() -> String {
    switch self {
    case .missingCommand:
      return Localized.Scripting.missingCommandErrorMessage
    case .missingArgument(_: let name):
      return String(format: Localized.Scripting.missingArgumentErrorMessage, name)
    case .editorNotFound(_: let documentName):
      return String(format: Localized.Scripting.editorNotFoundErrorMessage, documentName)
    case .jsEvaluationError(_: let error):
      guard let lineNumber = error.userInfo["WKJavaScriptExceptionLineNumber"] as? Int,
            let columnNumber = error.userInfo["WKJavaScriptExceptionColumnNumber"] as? Int,
            let errorMessage = error.userInfo["WKJavaScriptExceptionMessage"] as? String else {
        return Localized.Scripting.unknownJSErrorMessage
      }

      return String(
        format: Localized.Scripting.jsEvaluationErrorMessage,
        lineNumber,
        columnNumber,
        errorMessage
      )
    }
  }

  func applyToCommand(_ command: NSScriptCommand) {
    command.scriptErrorNumber = code
    command.scriptErrorString = localizedDescription()
  }
}
