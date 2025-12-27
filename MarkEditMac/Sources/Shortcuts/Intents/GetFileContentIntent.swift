//
//  GetFileContentIntent.swift
//  MarkEditMac
//
//  Created by cyan on 3/10/23.
//

import AppIntents

struct GetFileContentIntent: AppIntent {
  static let title: LocalizedStringResource = "Get File Content"
  static let description = IntentDescription("Gets file content of the active document; throws an error if no editor is opened.")

  @MainActor
  func perform() async throws -> some ReturnsValue<IntentFile> {
    guard let fileURL = currentEditor?.document?.textFileURL else {
      throw IntentError.missingDocument
    }

    return .result(value: IntentFile(fileURL: fileURL))
  }
}
