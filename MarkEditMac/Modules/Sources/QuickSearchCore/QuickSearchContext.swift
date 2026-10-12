//
//  QuickSearchContext.swift
//
//  Created by cyan on 10/11/26.
//

import Foundation

public struct QuickSearchLocations: Sendable {
  let urls: [URL]
  let filenameExtensions: Set<String>
  let showsHiddenFiles: Bool
  package let errors: [String]

  public init(
    urls: [URL],
    filenameExtensions: Set<String>,
    showsHiddenFiles: Bool,
    errors: [String] = []
  ) {
    self.urls = urls
    self.filenameExtensions = Set(filenameExtensions.map { $0.lowercased() })
    self.showsHiddenFiles = showsHiddenFiles
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
