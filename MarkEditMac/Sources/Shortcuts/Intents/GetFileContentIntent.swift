//
//  GetFileContentIntent.swift
//  MarkEditMac
//
//  Created by cyan on 3/10/23.
//

import AppIntents

@available(macOS 13.0, *)
struct GetFileContentIntent: AppIntent {
  static var title: LocalizedStringResource = "Get File Content"
  static var description = IntentDescription("Get file content of the active document, throws an error if no editor is opened.")

  @MainActor func perform() async throws -> some ReturnsValue {
    guard let fileURL = activeController?.document?.textFileURL else {
      throw IntentError.missingDocument
    }

    return .result(value: IntentFile(fileURL: fileURL))
  }
}
