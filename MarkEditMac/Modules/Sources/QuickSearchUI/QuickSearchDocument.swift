//
//  QuickSearchDocument.swift
//
//  Created by cyan on 10/11/26.
//

import Foundation
import QuickSearchCore

@MainActor
public struct QuickSearchDocument {
  let title: String
  let url: URL?
  let readSnapshot: () async throws -> QuickSearchDocumentSnapshot
  let gotoLine: (Int) async throws -> Void

  public init(
    title: String,
    url: URL?,
    readSnapshot: @escaping () async throws -> QuickSearchDocumentSnapshot,
    gotoLine: @escaping (Int) async throws -> Void
  ) {
    self.title = title
    self.url = url
    self.readSnapshot = readSnapshot
    self.gotoLine = gotoLine
  }
}

public enum QuickSearchDocumentError: Error {
  case unavailable
}
