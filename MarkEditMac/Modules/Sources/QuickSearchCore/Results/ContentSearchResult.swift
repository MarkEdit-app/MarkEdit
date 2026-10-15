//
//  ContentSearchResult.swift
//
//  Created by cyan on 10/11/26.
//

import Foundation

package struct ContentSearchResult: Sendable {
  package let lineNumber: Int
  package let snippet: String
  package let highlightedRange: NSRange

  static func search(_ query: String, text: String) throws -> [Self] {
    guard !query.isEmpty else {
      return []
    }

    var results: [Self] = []
    try Task.checkCancellation()

    let lines = text.split(omittingEmptySubsequences: false) {
      $0 == "\n" || $0 == "\r" || $0 == "\r\n"
    }

    for (index, substring) in lines.enumerated() {
      try Task.checkCancellation()

      let line = String(substring)
      guard let range = line.range(of: query, options: [.caseInsensitive, .literal]) else {
        continue
      }

      let start = line.index(range.lowerBound, offsetBy: -60, limitedBy: line.startIndex) ?? line.startIndex
      let end = line.index(range.upperBound, offsetBy: 120, limitedBy: line.endIndex) ?? line.endIndex
      let prefix = start == line.startIndex ? "" : "\u{2026}"
      let suffix = end == line.endIndex ? "" : "\u{2026}"
      let snippet = prefix + line[start..<end] + suffix
      let matchRange = NSRange(range, in: line)
      let startOffset = NSRange(line.startIndex..<start, in: line).length

      results.append(Self(
        lineNumber: index + 1,
        snippet: snippet,
        highlightedRange: NSRange(
          location: prefix.utf16.count + matchRange.location - startOffset,
          length: matchRange.length
        )
      ))
    }

    try Task.checkCancellation()
    return results
  }
}

package enum QuickSearchResult: Sendable {
  case file(FileSearchResult)
  case heading(HeadingSearchResult)
  case content(ContentSearchResult)
  case menuAction(MenuActionSearchResult)

  package var id: String {
    switch self {
    case .file(let result): "file:\(result.url.absoluteString)"
    case .heading(let result): "heading:\(result.heading.lineNumber)"
    case .content(let result): "line:\(result.lineNumber)"
    case .menuAction(let result): result.action.id
    }
  }

  package static func search(
    _ query: String,
    filter: QuickSearchFilter,
    recentURLs: [URL],
    bookmarkedURLs: [URL],
    snapshot: QuickSearchDocumentSnapshot?,
    menuActions: [MenuActionSearchResult.Action] = []
  ) throws -> [Self] {
    let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
    let urls: [URL]

    switch filter {
    case .all: urls = query.isEmpty ? recentURLs : recentURLs + bookmarkedURLs
    case .recents: urls = recentURLs
    case .bookmarks: urls = bookmarkedURLs
    case .headings, .contents, .menuActions: urls = []
    }

    var files = try FileSearchResult.search(query, urls: urls)
    if query.isEmpty && (filter == .all || filter == .recents) {
      files = Array(files.prefix(5))
    }

    let headings = try HeadingSearchResult.search(
      query,
      headings: filter == .all || filter == .headings ? snapshot?.headings ?? [] : []
    )

    let headingLines = Set(headings.map(\.heading.lineNumber))
    let content = try ContentSearchResult.search(
      query,
      text: filter == .all || filter == .contents ? snapshot?.text ?? "" : ""
    )
    .filter { !headingLines.contains($0.lineNumber) }
    .map(Self.content)

    let actions = try MenuActionSearchResult.search(
      query,
      actions: filter == .menuActions || filter == .all && !query.isEmpty ? menuActions : []
    )

    try Task.checkCancellation()

    guard filter == .all, !query.isEmpty else {
      return files.map(Self.file) + headings.map(Self.heading) + content + actions.map(Self.menuAction)
    }

    let recentURLs = Set(recentURLs.map(\.standardizedFileURL))
    var exactFiles: [Self] = []
    var prefixFiles: [Self] = []
    var recentFiles: [Self] = []
    var bookmarkedFiles: [Self] = []

    for file in files {
      try Task.checkCancellation()

      if file.match.rank == 0 {
        exactFiles.append(.file(file))
      } else if file.match.rank == 1 {
        prefixFiles.append(.file(file))
      } else if recentURLs.contains(file.url) {
        recentFiles.append(.file(file))
      } else {
        bookmarkedFiles.append(.file(file))
      }
    }

    let exactActions = actions.filter(\.isExactMatch).map(Self.menuAction)
    let prefixActions = actions.filter(\.isPrefixMatch).map(Self.menuAction)
    let otherActions = actions.filter { !$0.isExactMatch && !$0.isPrefixMatch }.map(Self.menuAction)

    return headings.map(Self.heading) + content
      + exactFiles + exactActions + prefixFiles + prefixActions + recentFiles + bookmarkedFiles + otherActions
  }
}
