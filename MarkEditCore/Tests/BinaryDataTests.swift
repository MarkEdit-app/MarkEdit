//
//  BinaryDataTests.swift
//
//  Created by cyan on 9/5/26.
//

import MarkEditCore
import XCTest

final class BinaryDataTests: XCTestCase {
  func testEmptyAndPlainText() {
    for text in ["", "hello\n", "\t\n\u{0B}\u{0C}\r", "\u{4F60}\u{597D} \u{1F600}"] {
      XCTAssertFalse(Data(text.utf8).isProbablyBinary)
    }
  }

  func testNonzeroBytesAreAllowed() {
    for byte in UInt8(1)...UInt8(0xFF) {
      XCTAssertFalse(Data(repeating: byte, count: 512).isProbablyBinary, "Byte: \(byte)")
    }
  }

  func testNULWithoutUTF16PatternIsBinary() {
    for data in [Data([0, 0]), Data([0, 1, 2]), Data([1, 0, 0]), Data("hello\0world".utf8)] {
      XCTAssertTrue(data.isProbablyBinary)
    }
  }

  func testShortAlternatingPatternsAreAllowed() {
    for data in [Data([0]), Data([0, 1]), Data([1, 0]), Data([0, 1, 0]), Data([1, 0, 1])] {
      XCTAssertFalse(data.isProbablyBinary)
    }
  }

  func testBOMLessUTF16() throws {
    for encoding in [String.Encoding.utf16BigEndian, .utf16LittleEndian] {
      let data = try XCTUnwrap("hello\n".data(using: encoding))
      XCTAssertFalse(data.isProbablyBinary)
    }
  }

  func testInvalidUTF8IsAllowed() {
    XCTAssertFalse(Data([0x63, 0x61, 0x66, 0xE9]).isProbablyBinary)
    XCTAssertFalse(Data([0xC3]).isProbablyBinary)
  }

  func testUTF8BOMDoesNotBypassNULCheck() {
    let bom = Data([0xEF, 0xBB, 0xBF])
    XCTAssertFalse(bom.isProbablyBinary)
    XCTAssertFalse((bom + Data("hello".utf8)).isProbablyBinary)
    XCTAssertTrue((bom + Data([0])).isProbablyBinary)
  }

  func testUTF16BOMBypassesContentValidation() {
    for bom in [Data([0xFE, 0xFF]), Data([0xFF, 0xFE])] {
      for contents in [Data(), Data([0]), Data([0, 0]), Data([0xD8, 0]), Data([0, 0xDC])] {
        XCTAssertFalse((bom + contents).isProbablyBinary)
      }
    }
  }

  func testBOMMustBeAtStart() {
    XCTAssertTrue(Data([1, 0xFE, 0xFF, 0]).isProbablyBinary)
    XCTAssertTrue(Data([1, 0xFF, 0xFE, 0]).isProbablyBinary)
  }

  func testUTF32HasNoSpecialHandling() {
    XCTAssertTrue(Data([0, 0, 0xFE, 0xFF, 0, 0, 0, 0x61]).isProbablyBinary)
    XCTAssertFalse(Data([0xFF, 0xFE, 0, 0, 0x61, 0, 0, 0]).isProbablyBinary)
  }

  func testNULAtScanBoundary() {
    XCTAssertTrue((Data(repeating: 0x61, count: 511) + Data([0])).isProbablyBinary)
    XCTAssertFalse((Data(repeating: 0x61, count: 512) + Data([0])).isProbablyBinary)
  }

  func testAlternatingPatternAtScanBoundary() {
    for startsWithZero in [false, true] {
      let pattern = Data((0..<512).map { offset -> UInt8 in
        offset.isMultiple(of: 2) == startsWithZero ? 0 : 0x61
      })

      XCTAssertFalse((pattern + Data([0, 0])).isProbablyBinary)
      let invalidLastByte: UInt8 = startsWithZero ? 0 : 0x61
      XCTAssertTrue((pattern.prefix(511) + Data([invalidLastByte])).isProbablyBinary)
    }
  }

  func testDataSlicesWithNonzeroStartIndex() {
    XCTAssertFalse(Data([1, 0xFE, 0xFF, 0, 0]).dropFirst().isProbablyBinary)
    XCTAssertFalse(Data([1, 0, 0x61, 0, 0x62]).dropFirst().isProbablyBinary)
    XCTAssertTrue(Data([1, 0, 0]).dropFirst().isProbablyBinary)
  }
}
