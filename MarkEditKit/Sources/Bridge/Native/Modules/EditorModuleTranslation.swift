//
//  EditorModuleTranslation.swift
//
//  Created by cyan on 11/29/25.
//

import Foundation
import NaturalLanguage
import Translation
import MarkEditCore

public final class EditorModuleTranslation: NativeModuleTranslation {
  public init() {}

  public func translate(text: String, from: String?, to: String?) async -> String {
    guard #available(macOS 26.0, *) else {
      return TranslationResponse(error: "Unsupported OS Version").jsonEncoded
    }

    do {
      let from = from ?? NLLanguageRecognizer.dominantLanguage(for: text)?.rawValue ?? "en-US"
      let session = TranslationSession(from: from, to: to)
      try? await session.prepareTranslation()
      let response = try await session.translate(text)
      return TranslationResponse(text: response.targetText).jsonEncoded
    } catch {
      return TranslationResponse(error: error.localizedDescription).jsonEncoded
    }
  }
}

// MARK: - Private

private struct TranslationResponse: Encodable {
  let text: String?
  let error: String?

  init(text: String? = nil, error: String? = nil) {
    self.text = text
    self.error = error
  }
}

@available(macOS 26.0, *)
private extension TranslationSession {
  convenience init(from: String, to: String?) {
    self.init(
      installedSource: Locale.Language(identifier: from),
      target: to.map { Locale.Language(identifier: $0) }
    )
  }
}
