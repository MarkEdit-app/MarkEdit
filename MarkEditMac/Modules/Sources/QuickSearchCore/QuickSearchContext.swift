//
//  QuickSearchContext.swift
//
//  Created by cyan on 10/11/26.
//

import Foundation

public struct QuickSearchLocations: Sendable {
  let urls: [URL]
  let showsHiddenFiles: Bool
  let isFileEligible: @Sendable (URL) -> Bool
  package let errors: [String]

  public init(
    urls: [URL],
    showsHiddenFiles: Bool,
    isFileEligible: @escaping @Sendable (URL) -> Bool,
    errors: [String] = []
  ) {
    self.urls = urls
    self.showsHiddenFiles = showsHiddenFiles
    self.isFileEligible = isFileEligible
    self.errors = errors
  }
}

public struct QuickSearchDocumentSnapshot: Equatable, Sendable {
  let text: String
  let headings: [QuickSearchHeading]

  public init(text: String, headings: [QuickSearchHeading] = []) {
    self.text = text
    self.headings = headings
  }
}

public struct QuickSearchHeading: Equatable, Sendable {
  package let title: String
  package let level: Int
  package let lineNumber: Int

  public init(title: String, level: Int, lineNumber: Int) {
    self.title = title
    self.level = level
    self.lineNumber = lineNumber
  }
}
