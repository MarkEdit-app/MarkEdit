//
//  FuzzyMatcher.swift
//
//  Created by cyan on 10/11/26.
//

import Foundation

package enum FuzzyMatcher {
  package struct Match: Sendable {
    let rank: Int
    let penalty: Int
    package let ranges: [NSRange]
  }

  static func match(_ query: String, text: String, matchFileStem: Bool = false) throws -> Match? {
    try Task.checkCancellation()

    let foldedQuery = fold(query)
    let needle = Array(foldedQuery)
    guard !needle.isEmpty else {
      return Match(rank: 0, penalty: 0, ranges: [])
    }

    var characters: [Character] = []
    var ranges: [NSRange] = []
    var offset = 0

    for (index, character) in text.enumerated() {
      if index.isMultiple(of: 256) {
        try Task.checkCancellation()
      }

      let string = String(character)
      let range = NSRange(location: offset, length: string.utf16.count)

      for folded in fold(string) {
        characters.append(folded)
        ranges.append(range)
      }

      offset += range.length
    }

    let stem = matchFileStem ? fold((text as NSString).deletingPathExtension) : nil
    let isExact = foldedQuery == stem || needle == characters
    var indices = Array(repeating: 0, count: needle.count)
    var best: Match?

    for start in characters.indices {
      if start.isMultiple(of: 256) {
        try Task.checkCancellation()
      }

      guard characters[start] == needle[0] else {
        continue
      }

      indices[0] = start

      // Greedy match positions only move forward as the starting position advances
      for position in needle.indices.dropFirst() {
        if position.isMultiple(of: 256) {
          try Task.checkCancellation()
        }

        var index = max(indices[position], indices[position - 1] + 1)

        while index < characters.count, characters[index] != needle[position] {
          if index.isMultiple(of: 256) {
            try Task.checkCancellation()
          }

          index += 1
        }

        guard index < characters.count else {
          return best
        }

        indices[position] = index
      }

      let gaps = indices[needle.count - 1] - start + 1 - needle.count
      let rank: Int
      if isExact {
        rank = 0
      } else if gaps == 0 && start == 0 {
        rank = 1
      } else if gaps == 0 {
        rank = 2
      } else {
        rank = 3
      }

      let boundaries = indices.filter {
        $0 == 0 || !characters[$0 - 1].isLetter && !characters[$0 - 1].isNumber
      }.count

      // For fuzzy matches, a word start offsets two skipped characters,
      // without outweighing long gaps.
      let boundaryBonus = rank == 3 ? 20 : 1
      let startPenalty = rank == 3 ? start * 10 : start
      let penalty = gaps * 10 + startPenalty - boundaries * boundaryBonus
      if let best, best.rank < rank || best.rank == rank && best.penalty <= penalty {
        continue
      }

      var highlights: [NSRange] = []
      for index in indices {
        let range = ranges[index]
        if let previous = highlights.last, NSMaxRange(previous) >= range.location {
          highlights[highlights.count - 1] = NSUnionRange(previous, range)
        } else {
          highlights.append(range)
        }
      }

      best = Match(rank: rank, penalty: penalty, ranges: highlights)
    }

    return best
  }

  private static func fold(_ text: String) -> String {
    text.folding(
      options: [.caseInsensitive, .diacriticInsensitive],
      locale: Locale(identifier: "en_US_POSIX")
    )
  }
}
