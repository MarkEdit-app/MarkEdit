//
//  RunJavaScriptScriptCommand.swift
//  MarkEdit
//
//  Created by Stephen Kaplan on 4/2/25.
//

import AppKit
import Carbon
import CoreServices

class RunJSScriptCommand: NSScriptCommand {
  @MainActor
  override func performDefaultImplementation() -> Any? {
    guard let inputString = self.directParameter as? String else {
      scriptErrorNumber = NSRequiredArgumentsMissingScriptError
      return nil
    }

    guard let currentEditor else {
      scriptErrorNumber = NSReceiverEvaluationScriptError
      return nil
    }

    // Preserve newlines for better error reporting
    let jsText = inputString.replacingOccurrences(of: "\\n", with: "\\\\n")

    suspendExecution()
    currentEditor.webView.evaluateJavaScript(jsText) { value, error in
      if let error = error as NSError? {
        // Raise AppleScript error
        if let lineNumber = error.userInfo["WKJavaScriptExceptionLineNumber"],
           let columnNumber = error.userInfo["WKJavaScriptExceptionColumnNumber"],
           let errorMessage = error.userInfo["WKJavaScriptExceptionMessage"] {
          self.scriptErrorString = "Line \(lineNumber), column \(columnNumber): \(errorMessage)"
        } else {
          self.scriptErrorString = "Unknown Error"
        }
        self.scriptErrorNumber = NSInternalScriptError
        self.resumeExecution(withResult: error.localizedDescription)
        return
      }

      // Pack JS value into AS-compatible ObjC objects
      let descriptor = NSAppleEventDescriptor(with: value)
      self.resumeExecution(withResult: descriptor)
    }
    return nil
  }
 }

private extension NSAppleEventDescriptor {
  convenience init(dictionary: [String: Any]) {
    self.init(recordDescriptor: ())
    let userRecord = Self.list()

    var currentIndex = 0
    for (key, value) in dictionary {
      // keyASUserRecordFields has a list of alternating keys and values
      let valueDescriptor = NSAppleEventDescriptor(with: value)
      let keyDescriptor = NSAppleEventDescriptor(string: key)

      userRecord.insert(keyDescriptor, at: currentIndex + 1)
      userRecord.insert(valueDescriptor, at: currentIndex + 2)

      /* keyASUserRecordFields reference:
       * https://developer.apple.com/documentation/professional-video-applications/supporting-conversions-with-scripting-class-extensions
       */
      self.setDescriptor(userRecord, forKeyword: UInt32(keyASUserRecordFields))
      currentIndex += 2
    }
  }

  convenience init(with value: Any?) {
    switch value {
    case nil:
      self.init()
    case let recordValue as [String: Any]:
      self.init(dictionary: recordValue)
    case let intValue as Int32:
      // Distinguish between `true` and `1`
      let mirror = Mirror(reflecting: value ?? NSObject())
      if mirror.subjectType != Mirror(reflecting: NSNumber(value: intValue)).subjectType, let booleanResult = value as? Bool {
        self.init(boolean: booleanResult)
      } else {
        self.init(int32: intValue)
      }
    case let doubleValue as Double:
      self.init(double: doubleValue)
    case let stringValue as String:
      if stringValue.hasPrefix("file://"), let url = URL(string: stringValue) {
        self.init(fileURL: url)
      } else if stringValue.hasPrefix("/") {
        let url = URL(fileURLWithPath: stringValue)
        self.init(fileURL: url)
      } else {
        self.init(string: stringValue)
      }
    case let arrayValue as [Any]:
      self.init(listDescriptor: ())
      for (index, element) in arrayValue.enumerated() {
        let valueDescriptor = NSAppleEventDescriptor(with: element)
        self.insert(valueDescriptor, at: index + 1)
      }
    default:
      print("No types recognized")
      self.init()
    }
  }
}
