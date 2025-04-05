//
//  EditorDocument+Scripting.swift
//  MarkEdit
//
//  Created by Stephen Kaplan on 4/2/25.
//

import Carbon
import MarkEditKit

extension EditorDocument {
  /// Raw markdown string of the document.
  @objc var source: String {
    get {
      return self.stringValue
    }
    set(newValue) {
      if newValue != self.stringValue {
        guard let targetEditor = targetEditor(for: nil) else { return }
        self.stringValue = newValue
        targetEditor.bridge.core.replaceText(text: newValue, granularity: .wholeDocument)
      }
    }
  }

  /// Rich text of the document.
  @objc var formattedText: NSTextStorage? {
      let markdownOptions = AttributedString.MarkdownParsingOptions(
        allowsExtendedAttributes: true,
        interpretedSyntax: .full,
        failurePolicy: .returnPartiallyParsedIfPossible,
        appliesSourcePositionAttributes: true
      )

      // Process lines separately to ensure they stay distinct
      let newlineString = NSAttributedString(string: "\n")
      let attributedSource = self.source.components(separatedBy: .newlines)
      .map { component in
        do {
          return try NSMutableAttributedString(markdown: component, options: markdownOptions)
        } catch {
          return NSMutableAttributedString(string: component)
        }
      }
      .reduce(into: NSMutableAttributedString()) { result, element in
        element.append(newlineString)
        result.append(element)
      }

      return NSTextStorage(attributedString: attributedSource)
  }

  /// Executes a user-provided JS script in the document's webview.
  @objc func handleEvaluateCommand(_ command: NSScriptCommand) -> Any? {
    guard let inputString = command.evaluatedArguments?["script"] as? String else {
      let scriptError = ScriptError.missingInput(message: "No JavaScript script provided")
      command.scriptErrorString = scriptError.localizedDescription
      command.scriptErrorNumber = scriptError.code
      return nil
    }

    guard let targetEditor = self.targetEditor(for: command) else {
      return nil
    }

    // Preserve newlines for better error reporting
    let jsText = inputString.replacingOccurrences(of: "\\n", with: "\\\\n")

    command.suspendExecution()
    targetEditor.webView.evaluateJavaScript(jsText) { value, error in
      if let error = error as NSError? {
        let scriptError = ScriptError.jsEvalError(jsError: error)
        command.scriptErrorString = scriptError.localizedDescription
        command.scriptErrorNumber = scriptError.code
        command.resumeExecution(withResult: error.localizedDescription)
        return
      }

      // Pack JS value into an AS-compatible descriptor
      let descriptor = NSAppleEventDescriptor(with: value)
      command.resumeExecution(withResult: descriptor)
    }
    return nil
  }
}

// MARK: - Private

private extension EditorDocument {
  func currentCommand() -> NSScriptCommand? {
    guard let currentCommand = NSScriptCommand.current() else {
      Logger.log(.error, "Couldn't find a command to handle incoming Apple Event.")
      return nil
    }
    return currentCommand
  }

  func targetEditor(for command: NSScriptCommand?) -> EditorViewController? {
    guard let currentCommand = command == nil ? currentCommand() : command else {
      Logger.log(.error, "Couldn't find a command to handle incoming Apple Event.")
      return nil
    }

    guard let targetEditor = self.windowControllers.first?.contentViewController as? EditorViewController else {
      let scriptError = ScriptError.missingInput(message: "Couldn't find active editor")
      currentCommand.scriptErrorString = scriptError.localizedDescription
      currentCommand.scriptErrorNumber = scriptError.code
      return nil
    }

    return targetEditor
  }
}

private extension NSAppleEventDescriptor {
  /// Initializes a descriptor from a dictionary with arbitrary keys using user record fields.
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

  /// Initializes a descriptor from an object by recursively packing values into their corresponding descriptor types.
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
      self.init()
    }
  }
}
