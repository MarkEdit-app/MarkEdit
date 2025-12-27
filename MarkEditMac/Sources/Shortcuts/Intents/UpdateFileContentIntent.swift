//
//  UpdateFileContentIntent.swift
//  MarkEditMac
//
//  Created by cyan on 3/10/23.
//

import AppIntents
import MarkEditKit

struct UpdateFileContentIntent: AppIntent {
  enum Granularity: String, AppEnum {
    case wholeDocument
    case selection

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
      TypeDisplayRepresentation(name: "Granularity")
    }

    static var caseDisplayRepresentations: [Self: DisplayRepresentation] {
      [
        .wholeDocument: "Whole Document",
        .selection: "Selection",
      ]
    }

    var replaceGranularity: ReplaceGranularity {
      switch self {
      case .wholeDocument: return .wholeDocument
      case .selection: return .selection
      }
    }
  }

  static let title: LocalizedStringResource = "Update File Content"
  static let description = IntentDescription("Updates file content of the active document; throws an error if no editor is opened.")
  static var parameterSummary: some ParameterSummary {
    Summary("Update file with \(\.$content)") {
      \.$granularity
      \.$saveChanges
    }
  }

  @Parameter(title: "Content")
  var content: String

  @Parameter(title: "Granularity", default: .wholeDocument)
  var granularity: Granularity

  @Parameter(title: "Save Changes")
  var saveChanges: Bool

  @MainActor
  func perform() async throws -> some IntentResult {
    guard let currentEditor else {
      throw IntentError.missingDocument
    }

    currentEditor.bridge.core.replaceText(
      text: content,
      granularity: granularity.replaceGranularity
    ) { _ in
      if saveChanges {
        currentEditor.document?.save(nil)
      }
    }

    return .result()
  }
}
