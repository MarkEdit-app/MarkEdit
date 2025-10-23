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
  static let description = IntentDescription("Create a new document, with optional parameters to set the file name and the initial content.")
  static let openAppWhenRun = true
  static var parameterSummary: some ParameterSummary {
    Summary("New Document named \(\.$fileName) with \(\.$initialContent)")
  }

  @Parameter(title: "File Name")
  var fileName: String?

  @Parameter(title: "Initial Content", default: "")
  var initialContent: String?

  @MainActor
  func perform() async throws -> some IntentResult {
    NSApp.appDelegate?.createNewFile(
      fileName: fileName,
      initialContent: initialContent,
      isIntent: true
    )

    return .result()
  }
}
