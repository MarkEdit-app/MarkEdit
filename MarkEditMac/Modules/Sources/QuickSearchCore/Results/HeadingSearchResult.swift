//
//  HeadingSearchResult.swift
//
//  Created by cyan on 10/11/26.
//

import Foundation

package struct HeadingSearchResult: Sendable {
  package let heading: QuickSearchHeading
  package let match: FuzzyMatcher.Match

  static func search(_ query: String, headings: [QuickSearchHeading]) throws -> [Self] {
    let matches = try headings.compactMap { heading -> Self? in
      try Task.checkCancellation()

      let prefix = query.hasPrefix("#") ? String(repeating: "#", count: heading.level) + " " : ""
      guard let match = try FuzzyMatcher.match(query, text: prefix + heading.title) else {
        return nil
      }

      let titleRange = NSRange(location: prefix.utf16.count, length: heading.title.utf16.count)
      let ranges = match.ranges.compactMap { range -> NSRange? in
        let intersection = NSIntersectionRange(range, titleRange)
        guard intersection.length > 0 else {
          return nil
        }

        return NSRange(location: intersection.location - titleRange.location, length: intersection.length)
      }

      return Self(heading: heading, match: .init(rank: match.rank, penalty: match.penalty, ranges: ranges))
    }

    return matches.sorted {
      if $0.match.rank != $1.match.rank {
        return $0.match.rank < $1.match.rank
      }

      if $0.match.penalty != $1.match.penalty {
        return $0.match.penalty < $1.match.penalty
      }

      return $0.heading.lineNumber < $1.heading.lineNumber
    }
  }
}
