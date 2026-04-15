//
//  StatisticsRuleTests.swift
//
//  Created by cyan on 4/15/26.
//

import XCTest
@testable import Statistics

final class StatisticsRuleTests: XCTestCase {
  func testCJKHanCharacters() {
    let rule = StatisticsRule(title: "CJK", icon: "character.textbox.zh", pattern: "\\p{Han}")
    XCTAssertEqual(rule.count(in: "你好世界"), 4)
    XCTAssertEqual(rule.count(in: "Hello World"), 0)
    XCTAssertEqual(rule.count(in: "Hello 你好 World"), 2)
  }

  func testCJKFullPattern() {
    let pattern = "[\\p{Han}\\u{3000}-\\u{303F}\\u{FF01}-\\u{FF60}\\u{FE30}-\\u{FE4F}\\u{2018}-\\u{201F}\\u{2013}\\u{2014}\\u{2026}]"
    let rule = StatisticsRule(title: "CJK", icon: "character.textbox.zh", pattern: pattern)

    // Han characters
    XCTAssertEqual(rule.count(in: "你好"), 2)
    // Fullwidth punctuation
    XCTAssertEqual(rule.count(in: "！？"), 2)
    // CJK symbols: ideographic comma and period
    XCTAssertEqual(rule.count(in: "、。"), 2)
    // Em dash and ellipsis
    XCTAssertEqual(rule.count(in: "\u{2014}\u{2026}"), 2)
    // Smart quotes
    XCTAssertEqual(rule.count(in: "\u{201C}\u{201D}"), 2)
    // ASCII not counted
    XCTAssertEqual(rule.count(in: "Hello, world!"), 0)
  }

  func testJapaneseKana() {
    let pattern = "[\\u{3040}-\\u{309F}\\u{30A0}-\\u{30FF}]"
    let rule = StatisticsRule(title: "Kana", icon: "character.textbox.ja", pattern: pattern)
    XCTAssertEqual(rule.count(in: "ひらがな"), 4)
    XCTAssertEqual(rule.count(in: "カタカナ"), 4)
    XCTAssertEqual(rule.count(in: "漢字"), 0)
  }

  func testKoreanHangul() {
    let pattern = "[\\u{AC00}-\\u{D7AF}\\u{1100}-\\u{11FF}\\u{3130}-\\u{318F}]"
    let rule = StatisticsRule(title: "Hangul", icon: "character.textbox.ko", pattern: pattern)
    XCTAssertEqual(rule.count(in: "한글"), 2)
    XCTAssertEqual(rule.count(in: "Hello"), 0)
  }

  func testEmoji() {
    let rule = StatisticsRule(title: "Emoji", icon: "face.smiling", pattern: "\\p{Emoji_Presentation}")
    XCTAssertEqual(rule.count(in: "Hello 😀🎉🚀"), 3)
    XCTAssertEqual(rule.count(in: "No emoji here"), 0)
  }

  func testInvalidPattern() {
    let rule = StatisticsRule(title: "Bad", icon: "xmark", pattern: "[invalid")
    XCTAssertEqual(rule.count(in: "anything"), 0)
  }

  func testEmptyText() {
    let rule = StatisticsRule(title: "CJK", icon: "character.textbox.zh", pattern: "\\p{Han}")
    XCTAssertEqual(rule.count(in: ""), 0)
  }

  func testDecodingFromJSON() throws {
    let json = """
    [
      {
        "title": "CJK Characters",
        "icon": "character.textbox.zh",
        "pattern": "\\\\p{Han}"
      }
    ]
    """

    let rules = try JSONDecoder().decode([StatisticsRule].self, from: Data(json.utf8))
    XCTAssertEqual(rules.count, 1)
    XCTAssertEqual(rules[0].title, "CJK Characters")
    XCTAssertEqual(rules[0].count(in: "你好"), 2)
  }
}
