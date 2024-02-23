//
//  GetFileContentIntent.swift
//  MarkEditMac
//
//  Created by cyan on 3/10/23.
//

import AppIntents

struct GetFileContentIntent: AppIntent {
  static var title: LocalizedStringResource = "Get File Content"
  static var description = IntentDescription("Get file content of the active document, throws an error if no editor is opened.")

  @MainActor
  func perform() async throws -> some ReturnsValue<IntentFile> {
    guard let fileURL = activeController?.document?.textFileURL else {
      throw IntentError.missingDocument
    }

    guard let fileData = try? Data(contentsOf: fileURL) else {
      throw IntentError.missingDocument
    }

    return .result(value: IntentFile(data: fileData, filename: fileURL.lastPathComponent))
  }
}
