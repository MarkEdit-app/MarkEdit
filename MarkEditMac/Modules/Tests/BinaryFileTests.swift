//
//  BinaryFileTests.swift
//
//  Created by cyan on 9/5/26.
//

import MarkEditKit
import XCTest

final class BinaryFileTests: XCTestCase {
  func testExtensionlessText() throws {
    for text in ["", "hello\n", "tab\tCR\rLF\n", "\u{4F60}\u{597D} \u{1F600}\n"] {
      let binary = try classify(Data(text.utf8))
      XCTAssertFalse(binary)
    }
  }

  func testNULWithoutUTF16PatternIsBinary() throws {
    for data in [Data([0, 0]), Data([0, 1, 2]), Data("hello\0world".utf8)] {
      let binary = try classify(data)
      XCTAssertTrue(binary)
    }
  }

  func testNonNULControlBytesAreAllowed() throws {
    let binary = try classify(Data([1, 2, 3, 0x1B, 0x7F]))
    XCTAssertFalse(binary)
  }

  func testLegacyEncodingIsNotRejectedAsInvalidUTF8() throws {
    let binary = try classify(Data([0x63, 0x61, 0x66, 0xE9, 0x0A]))
    XCTAssertFalse(binary)
  }

  func testUnicodeBOMs() throws {
    let formats: [([UInt8], String.Encoding)] = [
      ([0xEF, 0xBB, 0xBF], .utf8),
      ([0xFE, 0xFF], .utf16BigEndian),
      ([0xFF, 0xFE], .utf16LittleEndian),
    ]

    for (bom, encoding) in formats {
      let text = try XCTUnwrap("hello \u{1F600}\n".data(using: encoding))
      let binary = try classify(Data(bom) + text)
      XCTAssertFalse(binary, "Encoding: \(encoding)")
    }
  }

  func testUTF16BOMBypassesBinaryChecks() throws {
    let binary = try classify(Data([0xFE, 0xFF, 0x00, 0x00, 0x00, 0x01]))
    XCTAssertFalse(binary)
  }

  func testUTF16BOMDoesNotRequireValidUnicode() throws {
    for data in [Data([0xFE, 0xFF, 0x00]), Data([0xFE, 0xFF, 0xD8, 0x00])] {
      let binary = try classify(data)
      XCTAssertFalse(binary)
    }
  }

  func testBOMLessUTF16() throws {
    for encoding in [String.Encoding.utf16BigEndian, .utf16LittleEndian] {
      let data = try XCTUnwrap("hello\n".data(using: encoding))
      XCTAssertFalse(try classify(data))
    }
  }

  func testSampleEndingInsideUTF8Character() throws {
    let data = Data((String(repeating: "a", count: 511) + "\u{1F600}").utf8)
    let binary = try classify(data)
    XCTAssertFalse(binary)
  }

  func testSampleEndingInsideUTF16SurrogatePair() throws {
    let text = String(repeating: "a", count: 254) + "\u{1F600}"
    let data = Data([0xFE, 0xFF]) + (try XCTUnwrap(text.data(using: .utf16BigEndian)))
    let binary = try classify(data)
    XCTAssertFalse(binary)
  }

  func testOnlyThePrefixIsInspected() throws {
    let binary = try classify(Data(repeating: 0x61, count: 512) + Data([0]))
    XCTAssertFalse(binary)
  }

  func testNULAtEndOfSampleIsBinary() throws {
    XCTAssertTrue(try classify(Data(repeating: 0x61, count: 511) + Data([0])))
  }

  func testUnknownExtensionKeepsMetadataClassification() throws {
    let name = "sample.markedit-unknown-type-1732"
    let text = try classify(Data("hello\n".utf8), name: name)
    let binary = try classify(Data([0, 1, 2]), name: name)

    XCTAssertTrue(text)
    XCTAssertTrue(binary)
  }

  func testKnownTypesKeepExistingBehavior() throws {
    let markdown = try classify(Data([0, 1, 2]), name: "sample.MD")
    let image = try classify(Data("hello".utf8), name: "sample.png")
    let pdf = try classify(Data("hello".utf8), name: "sample.pdf")

    XCTAssertFalse(markdown)
    XCTAssertTrue(image)
    XCTAssertTrue(pdf)
  }

  func testMissingFileKeepsMetadataFallback() {
    let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    XCTAssertFalse(url.isBinaryFile)
  }
}

private extension BinaryFileTests {
  func classify(_ data: Data, name: String = "sample") throws -> Bool {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let url = directory.appending(path: name, directoryHint: .notDirectory)
    try data.write(to: url)
    return url.isBinaryFile
  }
}
