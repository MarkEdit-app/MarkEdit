//
//  FileSearchResult.swift
//
//  Created by cyan on 10/12/26.
//

import Foundation

package struct FileSearchResult: Sendable {
  package let url: URL
  package let match: FuzzyMatcher.Match

  static func search(_ query: String, urls: [URL]) throws -> [Self] {
    var seen = Set<URL>()

    let matches = try urls.compactMap { url -> Self? in
      try Task.checkCancellation()

      let url = url.standardizedFileURL
      guard seen.insert(url).inserted,
            let match = try FuzzyMatcher.match(query, text: url.lastPathComponent, matchFileStem: true) else {
        return nil
      }

      return Self(url: url, match: match)
    }

    return matches
      .enumerated()
      .sorted {
        if $0.element.match.rank != $1.element.match.rank {
          return $0.element.match.rank < $1.element.match.rank
        }

        if $0.element.match.penalty != $1.element.match.penalty {
          return $0.element.match.penalty < $1.element.match.penalty
        }

        return $0.offset < $1.offset
      }
      .map(\.element)
  }
}
