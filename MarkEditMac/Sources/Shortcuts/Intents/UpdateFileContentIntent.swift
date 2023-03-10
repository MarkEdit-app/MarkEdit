//
//  UpdateFileContentIntent.swift
//  MarkEditMac
//
//  Created by cyan on 3/10/23.
//

import AppIntents
import MarkEditKit

@available(macOS 13.0, *)
struct UpdateFileContentIntent: AppIntent {
  enum Granularity: String, AppEnum {
    case fullDocument
    case selection

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Granularity")
    static var caseDisplayRepresentations: [Granularity: DisplayRepresentation] = [
      .fullDocument: "Full Document",
      .selection: "Selection",
    ]

    var replaceGranularity: ReplaceGranularity {
      switch self {
      case .fullDocument: return .fullDocument
      case .selection: return .selection
      }
    }
  }

  static var title: LocalizedStringResource = "Update File Content"
  static var description = IntentDescription("Update file content of the active document, throws an error if no editor is opened.")
  static var parameterSummary: some ParameterSummary {
    Summary("Update file with \(\.$content)") {
      \.$granularity
      \.$saveChanges
    }
  }

  @Parameter(title: "Content")
  var content: String

  @Parameter(title: "Granularity", default: .fullDocument)
  var granularity: Granularity

  @Parameter(title: "Save Changes")
  var saveChanges: Bool

  func perform() async throws -> some IntentResult {
    guard let activeController = await activeController else {
      throw IntentError.missingDocument
    }

    Task { @MainActor in
      activeController.bridge.core.replaceText(
        text: content,
        granularity: granularity.replaceGranularity
      ) { _ in
        if saveChanges {
          activeController.document?.save(nil)
        }
      }
    }

    return .result(value: true)
  }
}
