//
//  QuickSearchDocument.swift
//
//  Created by cyan on 10/11/26.
//

import Foundation
import QuickSearchCore

@MainActor
public struct QuickSearchDocument {
  let id: UUID
  let title: String
  let url: URL?
  let readSnapshot: () async throws -> QuickSearchDocumentSnapshot
  let gotoLine: (Int) async throws -> Void

  public init(
    id: UUID = UUID(),
    title: String,
    url: URL?,
    readSnapshot: @escaping () async throws -> QuickSearchDocumentSnapshot,
    gotoLine: @escaping (Int) async throws -> Void
  ) {
    self.id = id
    self.title = title
    self.url = url
    self.readSnapshot = readSnapshot
    self.gotoLine = gotoLine
  }
}

public enum QuickSearchDocumentError: Error {
  case unavailable
}
