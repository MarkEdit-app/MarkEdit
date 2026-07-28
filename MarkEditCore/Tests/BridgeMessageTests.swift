//
//  BridgeMessageTests.swift
//
//  Created by cyan on 7/29/26.
//

import MarkEditCore
import XCTest

final class BridgeMessageTests: XCTestCase {
  private struct Nested: Codable, Equatable {
    var x: Int
    var y: Int
  }

  // Mirrors what ts-gyb used to synthesize for the web side
  private struct Synthesized: Encodable {
    var flag: Bool
    var text: String
    var count: Int
    var nested: Nested
    var list: [String]
    var absent: String?
    var present: String?
  }

  private struct Message: Decodable {
    var text: String?
    var count: Int
    var flag: Bool
    var nested: Nested
    var list: [String]?

    init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: BridgeFieldKey.self)
      text = try container.value("text")
      count = try container.value("count")
      flag = try container.value("flag")
      nested = try container.value("nested")
      list = try container.value("list")
    }
  }

  func testEncodingMatchesSynthesized() {
    let synthesized = Synthesized(
      flag: true,
      text: "a",
      count: 3,
      nested: Nested(x: 1, y: 2),
      list: ["p", "q"],
      absent: nil,
      present: "here"
    )

    let message = BridgeMessage(
      ("flag", synthesized.flag),
      ("text", synthesized.text),
      ("count", synthesized.count),
      ("nested", synthesized.nested),
      ("list", synthesized.list),
      ("absent", synthesized.absent),
      ("present", synthesized.present)
    )

    XCTAssertEqual(encoded(synthesized), encoded(message))
    XCTAssertFalse(encoded(message).contains("absent"))
  }

  func testEncodingEmptyMessage() {
    XCTAssertEqual(encoded(BridgeMessage()), "{}")
  }

  func testDecodingPresentValues() throws {
    let message = try decoded(#"{"text":"hi","count":3,"flag":true,"nested":{"x":1,"y":2},"list":["a"]}"#)
    XCTAssertEqual(message.text, "hi")
    XCTAssertEqual(message.count, 3)
    XCTAssertTrue(message.flag)
    XCTAssertEqual(message.nested, Nested(x: 1, y: 2))
    XCTAssertEqual(message.list, ["a"])
  }

  func testDecodingMissingOptionals() throws {
    let message = try decoded(#"{"count":3,"flag":false,"nested":{"x":1,"y":2}}"#)
    XCTAssertNil(message.text)
    XCTAssertNil(message.list)
  }

  func testDecodingNullOptionals() throws {
    let message = try decoded(#"{"text":null,"count":0,"flag":true,"nested":{"x":1,"y":2},"list":null}"#)
    XCTAssertNil(message.text)
    XCTAssertNil(message.list)
  }

  func testDecodingMissingRequiredValue() {
    XCTAssertThrowsError(try decoded(#"{"count":1,"flag":true}"#))
  }
}

// MARK: - Private

extension BridgeMessageTests {
  private func encoded(_ value: Encodable) -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    let data = (try? encoder.encode(value)) ?? Data()
    return String(bytes: data, encoding: .utf8) ?? ""
  }

  private func decoded(_ json: String) throws -> Message {
    try JSONDecoder().decode(Message.self, from: Data(json.utf8))
  }
}
