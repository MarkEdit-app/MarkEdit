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
    NSApp.appDelegate?.createUntitledFile(initialContent: initialContent, isIntent: true)
    return .result()
  }
}
