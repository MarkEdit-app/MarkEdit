//
//  Error+Scripting.swift
//  MarkEdit
//
//  Created by Stephen Kaplan on 4/4/25.
//

enum ScriptingError: Error, LocalizedError {
  case missingCommand
  case missingArgument(_ name: String)
  case editorNotFound(_ documentName: String)
  case jsEvaluationError(_ jsError: NSError)

  var code: Int {
    switch self {
    case .missingCommand:
      return NSCannotCreateScriptCommandError
    case .missingArgument:
      return NSArgumentEvaluationScriptError
    case .editorNotFound:
      return NSReceiverEvaluationScriptError
    case .jsEvaluationError(_: let jsError):
      return jsError.code // WKError.javaScriptExceptionOccurred -- 4
    }
  }

  func localizedDescription() -> String {
    switch self {
    case .missingCommand:
      return Localized.Scripting.missingCommandErrorMeesage
    case .missingArgument(_: let name):
      return String(format: Localized.Scripting.missingArgumentErrorMessage, name)
    case .editorNotFound(_: let documentName):
      return String(format: Localized.Scripting.editorNotFoundErrorMessage, documentName)
    case .jsEvaluationError(_: let error):
      if let lineNumber = error.userInfo["WKJavaScriptExceptionLineNumber"] as? Int,
         let columnNumber = error.userInfo["WKJavaScriptExceptionColumnNumber"] as? Int,
         let errorMessage = error.userInfo["WKJavaScriptExceptionMessage"] as? String {
        return String(format: Localized.Scripting.jsEvaluationErrorMessage, lineNumber, columnNumber, errorMessage)
      } else {
        return Localized.Scripting.unknownJSErrorMessage
      }
    }
  }

  func applyToCommand(_ command: NSScriptCommand) {
    command.scriptErrorNumber = code
    command.scriptErrorString = localizedDescription()
  }
}
