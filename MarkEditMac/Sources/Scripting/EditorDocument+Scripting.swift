//
//  EditorDocument+Scripting.swift
//  MarkEditMac
//
//  Created by Stephen Kaplan on 4/2/25.
//

import MarkEditKit

extension EditorDocument {
  /// Raw markdown string of the document.
  @objc var scriptingSource: String {
    get {
      return stringValue
    }
    set {
      guard newValue != stringValue else {
        return
      }

      guard let targetEditor = scriptingTargetEditor(for: nil) else {
        return
      }

      stringValue = newValue
      targetEditor.bridge.core.replaceText(text: newValue, granularity: .wholeDocument)
    }
  }

  /// Rich text of the document.
  @objc var scriptingRichText: NSTextStorage? {
    let markdownOptions = AttributedString.MarkdownParsingOptions(
      allowsExtendedAttributes: true,
      interpretedSyntax: .full,
      failurePolicy: .returnPartiallyParsedIfPossible,
      appliesSourcePositionAttributes: true
    )

    // Process lines separately to ensure they stay distinct
    let newlineString = NSAttributedString(string: "\n")
    let attributedSource = scriptingSource.components(separatedBy: .newlines)
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

  @objc var scriptingSelectedText: String {
    get {
      guard let command = currentScriptCommand(),
            let targetEditor = scriptingTargetEditor(for: command) else {
        return ""
      }

      command.suspendExecution()

      Task {
        let text = try await targetEditor.bridge.selection.getText()
        command.resumeExecution(withResult: NSAppleEventDescriptor(with: text))
      }

      return stringValue
    }
    set {
      guard let targetEditor = scriptingTargetEditor(for: nil) else {
        return
      }

      Task {
        targetEditor.bridge.core.replaceText(text: newValue, granularity: .selection)
      }
    }
  }

  /// Executes a user-provided JS script in the document's web view.
  @objc func scriptingHandleEvaluateCommand(_ command: NSScriptCommand) -> Any? {
    guard let script = command.evaluatedArguments?["script"] as? String else {
      ScriptingError.missingArgument("script").applyToCommand(command)
      return nil
    }

    guard let targetEditor = scriptingTargetEditor(for: command) else {
      return nil
    }

    command.suspendExecution()
    targetEditor.webView.evaluateJavaScript(script) { value, error in
      if let error = error as NSError? {
        ScriptingError.jsEvaluationError(error).applyToCommand(command)
        command.resumeExecution(withResult: NSAppleEventDescriptor.null())
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
  func currentScriptCommand() -> NSScriptCommand? {
    guard let currentCommand = NSScriptCommand.current() else {
      Logger.log(.error, ScriptingError.missingCommand.localizedDescription)
      return nil
    }

    return currentCommand
  }

  func scriptingTargetEditor(for command: NSScriptCommand?) -> EditorViewController? {
    guard let currentCommand = command == nil ? currentScriptCommand() : command else {
      Logger.log(.error, ScriptingError.missingCommand.localizedDescription)
      return nil
    }

    guard let targetEditor = windowControllers.first?.contentViewController as? EditorViewController else {
      let documentName = displayName ?? defaultDraftName()
      ScriptingError.editorNotFound(documentName).applyToCommand(currentCommand)
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
      let keyASUserRecordFields: UInt32 = 1970500198
      setDescriptor(userRecord, forKeyword: UInt32(keyASUserRecordFields))
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
        insert(valueDescriptor, at: index + 1)
      }
    default:
      self.init()
    }
  }
}
