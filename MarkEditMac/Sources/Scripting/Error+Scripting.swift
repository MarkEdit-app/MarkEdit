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
  case invalidDestination(_ fileURL: URL, document: EditorDocument)
  case extensionMistach(_ fileURL: URL, expectedExtension: String, outputType: String)

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
    case .invalidDestination:
      return NSArgumentsWrongScriptError
    case .extensionMistach:
      return NSArgumentsWrongScriptError
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
    case let .invalidDestination(_: fileURL, document: document):
      let validTypes = document.writableTypes(for: .saveOperation)
      let validExtensions = validTypes.compactMap {
        document.fileNameExtension(forType: $0, saveOperation: .saveOperation)
      }
      return String(format: Localized.Scripting.invalidDestinationErrorMessage, fileURL.pathExtension, validExtensions.joined(separator: ", "))
    case let .extensionMistach(_, expectedExtension: expectedExtension, outputType: outputType):
      return String(format: Localized.Scripting.extensionMismatchErrorMessage, outputType, expectedExtension)
    }
  }

  func applyToCommand(_ command: NSScriptCommand) {
    command.scriptErrorNumber = code
    command.scriptErrorString = localizedDescription()
  }
}
