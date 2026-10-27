//
//  FileSearchResult.swift
//
//  Created by cyan on 10/12/26.
//

import Foundation

package struct FileSearchResult: Sendable {
  package let url: URL
  package let match: FuzzyMatcher.Match
  package let matchedFolderIndex: Int?

  private var sortKey: (Int, Int, Int) {
    (matchedFolderIndex == nil ? 0 : 1, match.rank, match.penalty)
  }

  static func search(_ query: String, urls: [URL]) throws -> [Self] {
    var seen = Set<URL>()

    let matches = try urls.compactMap { url -> Self? in
      try Task.checkCancellation()

      let url = url.standardizedFileURL
      guard seen.insert(url).inserted else {
        return nil
      }

      if let match = try FuzzyMatcher.match(query, text: url.lastPathComponent, matchFileStem: true) {
        return Self(url: url, match: match, matchedFolderIndex: nil)
      }

      let folders = url.pathComponents.filter { $0 != "/" }.dropLast()
      var best: Self?
      for (index, folder) in folders.enumerated().reversed() {
        guard let match = try FuzzyMatcher.match(query, text: folder) else {
          continue
        }

        let result = Self(url: url, match: match, matchedFolderIndex: index)
        if let best, best.sortKey <= result.sortKey {
          continue
        }

        best = result
      }

      return best
    }

    return matches
      .enumerated()
      .sorted {
        if $0.element.sortKey != $1.element.sortKey {
          return $0.element.sortKey < $1.element.sortKey
        }

        return $0.offset < $1.offset
      }
      .map(\.element)
  }
}
