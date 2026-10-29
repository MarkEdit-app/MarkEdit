//
//  MenuActionSearchResult.swift
//
//  Created by cyan on 10/12/26.
//

import Foundation

package struct MenuActionSearchResult: Sendable {
  package struct Action: Sendable {
    package let indices: [Int]
    package let titles: [String]
    package let shortcutHint: String?

    var id: String {
      "menu:" + indices.map(String.init).joined(separator: ".")
    }

    package var title: String {
      titles.last ?? ""
    }

    package var subtitle: String {
      titles.joined(separator: " \u{203A} ")
    }

    package init(indices: [Int], titles: [String], shortcutHint: String? = nil) {
      self.indices = indices
      self.titles = titles
      self.shortcutHint = shortcutHint
    }
  }

  package let action: Action
  let match: FuzzyMatcher.Match
  let isMenuMatch: Bool

  var isExactMatch: Bool {
    !isMenuMatch && match.rank == 0
  }

  var isPrefixMatch: Bool {
    !isMenuMatch && match.rank == 1
  }

  package var highlightedRanges: [NSRange] {
    isMenuMatch ? [] : match.ranges
  }

  private var sortKey: (Int, Int, Int) {
    let group: Int
    switch (match.rank == 3, isMenuMatch) {
    case (false, false): group = 0
    case (false, true): group = 1
    case (true, false): group = 2
    case (true, true): group = 3
    }

    return (group, match.rank, match.penalty)
  }

  static func search(_ query: String, actions: [Action]) throws -> [Self] {
    try actions.compactMap { action -> Self? in
      try Task.checkCancellation()

      let titleMatch = try matchTitle(query, title: action.title).map {
        Self(action: action, match: $0, isMenuMatch: false)
      }

      guard !query.isEmpty,
            let menuTitle = action.titles.dropLast().last,
            let match = try matchTitle(query, title: menuTitle) else {
        return titleMatch
      }

      let menuMatch = Self(action: action, match: match, isMenuMatch: true)
      if let titleMatch, titleMatch.sortKey < menuMatch.sortKey {
        return titleMatch
      }

      return menuMatch
    }
    .sorted {
      if $0.sortKey != $1.sortKey {
        return $0.sortKey < $1.sortKey
      }

      return $0.action.indices.lexicographicallyPrecedes($1.action.indices)
    }
  }

  private static func matchTitle(_ query: String, title: String) throws -> FuzzyMatcher.Match? {
    let suffixLength = title.hasSuffix("\u{2026}") ? 1 : title.hasSuffix("...") ? 3 : 0
    if suffixLength > 0, let match = try FuzzyMatcher.match(query, text: String(title.dropLast(suffixLength))) {
      return match
    }

    return try FuzzyMatcher.match(query, text: title)
  }
}
