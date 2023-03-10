//
//  CreateNewDocumentIntent.swift
//  MarkEditMac
//
//  Created by cyan on 3/10/23.
//

import AppKit
import AppIntents

@available(macOS 13.0, *)
struct CreateNewDocumentIntent: AppIntent {
  static var title: LocalizedStringResource = "Create New Document"
  static var description = IntentDescription("Create a new document, with an optional parameter to specify the initial content.")
  static var openAppWhenRun = true
  static var parameterSummary: some ParameterSummary {
    Summary("New Document with \(\.$initialContent)")
  }

  @Parameter(title: "Initial Content")
  var initialContent: String?

  func perform() async throws -> some IntentResult {
    await NSDocumentController.shared.newDocument(nil)
    await NSApp.activate(ignoringOtherApps: true)

    DispatchQueue.afterDelay(seconds: 0.2) {
      Task { @MainActor in
        if let initialContent {
          activeController?.bridge.core.insertText(text: initialContent, from: 0, to: 0)
        }
      }
    }

    return .result(value: true)
  }
}
