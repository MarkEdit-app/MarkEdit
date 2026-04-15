//
//  StatisticsRule.swift
//
//  Created by cyan on 4/15/26.
//

import Foundation

/**
 A user-defined rule for counting custom statistics.

 Rules are loaded from "statistics-rules.json" in AppCustomization.
 Each rule uses a regex pattern to count matches in the document text.

 Example JSON:
 ```json
 [
   {
     "title": "Emoji",
     "icon": "face.smiling",
     "pattern": "\\p{Emoji_Presentation}"
   }
 ]
 ```
 */
public struct StatisticsRule: Codable, Sendable {
  public let title: String
  public let icon: String
  public let pattern: String

  public init(title: String, icon: String, pattern: String) {
    self.title = title
    self.icon = icon
    self.pattern = pattern
  }

  func count(in text: String) -> Int {
    guard let regex = try? Regex(pattern) else {
      return 0
    }

    return text.matches(of: regex).count
  }
}

struct StatisticsRuleResult: Sendable {
  let rule: StatisticsRule
  let count: Int

  var isEmpty: Bool {
    count == 0 // swiftlint:disable:this empty_count
  }
}
