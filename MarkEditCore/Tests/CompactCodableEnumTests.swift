//
//  CompactCodableEnumTests.swift
//
//  Created by cyan on 7/29/26.
//

import MarkEditCore
import XCTest

final class CompactCodableEnumTests: XCTestCase {
  private enum Sample: String, CaseIterable, CompactCodableEnum {
    case twoSpaces
    case fourSpaces
  }

  // Mirrors what Swift synthesizes for a payload-free Codable enum
  private enum Legacy: Codable {
    case twoSpaces
    case fourSpaces
  }

  func testEncodingMatchesLegacy() throws {
    XCTAssertEqual(encoded(Sample.twoSpaces), encoded(Legacy.twoSpaces))
    XCTAssertEqual(encoded(Sample.fourSpaces), encoded(Legacy.fourSpaces))
    XCTAssertEqual(encoded(Sample.twoSpaces), #"{"twoSpaces":{}}"#)
  }

  func testDecodingLegacyValue() throws {
    let value = try JSONDecoder().decode(Sample.self, from: Data(#"{"fourSpaces":{}}"#.utf8))
    XCTAssertEqual(value, .fourSpaces)
  }

  func testDecodingPlainValue() throws {
    let value = try JSONDecoder().decode(Sample.self, from: Data(#""fourSpaces""#.utf8))
    XCTAssertEqual(value, .fourSpaces)
  }

  func testDecodingUnknownValue() {
    XCTAssertThrowsError(try JSONDecoder().decode(Sample.self, from: Data(#"{"eightSpaces":{}}"#.utf8)))
  }

  func testRoundTrip() throws {
    for value in Sample.allCases {
      let data = try JSONEncoder().encode(value)
      XCTAssertEqual(try JSONDecoder().decode(Sample.self, from: data), value)
    }
  }
}

// MARK: - Private

extension CompactCodableEnumTests {
  private func encoded(_ value: Encodable) -> String {
    let data = (try? JSONEncoder().encode(value)) ?? Data()
    return String(bytes: data, encoding: .utf8) ?? ""
  }
}
