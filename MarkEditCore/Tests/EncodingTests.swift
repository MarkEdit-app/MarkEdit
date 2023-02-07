//
//  EncodingTests.swift
//
//  Created by cyan on 2/2/23.
//

import MarkEditCore
import XCTest

final class EncodingTests: XCTestCase {
  func testDecodeUTF8() {
    let data = fileData(of: "sample-utf8.md")
    XCTAssertEqual(data.toString(), "Hello, World!\n")
  }

  func testDecodeGB18030() {
    let data = fileData(of: "sample-gb18030.md")
    XCTAssertEqual(data.toString(), "你好，世界！\n")
  }

  func testDecodeJapaneseEUC() {
    let data = fileData(of: "sample-japanese-euc.md")
    XCTAssertEqual(data.toString(), "ゼルダの伝説\n")
  }

  func testDecodeKoreanEUC() {
    let data = fileData(of: "sample-korean-euc.md")
    XCTAssertEqual(data.toString(), "오징어 게임\n")
  }
}

// MARK: - Private

private extension EncodingTests {
  func fileData(of name: String) -> Data {
    // swiftlint:disable:next force_unwrapping
    let url = Bundle.module.url(forResource: name, withExtension: nil)!
    // swiftlint:disable:next force_try
    return try! Data(contentsOf: url)
  }
}
