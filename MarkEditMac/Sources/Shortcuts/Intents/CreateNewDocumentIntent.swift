//
//  CreateNewDocumentIntent.swift
//  MarkEditMac
//
//  Created by cyan on 3/10/23.
//

import AppKit
import AppIntents

struct CreateNewDocumentIntent: AppIntent {
  static let title: LocalizedStringResource = "Create New Document"
  static let description = IntentDescription("Create a new document, with an optional parameter to specify the initial content.")
  static let openAppWhenRun = true
  static var parameterSummary: some ParameterSummary {
    Summary("New Document with \(\.$initialContent)")
  }

  @Parameter(title: "Initial Content")
  var initialContent: String?

  @MainActor
  func perform() async throws -> some IntentResult {
    NSDocumentController.shared.newDocument(nil)
    NSApp.activate(ignoringOtherApps: true)

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      if let initialContent {
        activeController?.bridge.core.insertText(text: initialContent, from: 0, to: 0)
      }
    }

    return .result()
  }
}
