//
//  TextBundleTests.swift
//
//  Created by cyan on 3/23/23.
//

import TextBundle
import XCTest

// MARK: - Private

final class TextBundleTests: XCTestCase {
  func testTextBundleParsing() {
    // swiftlint:disable:next force_unwrapping
    let url = Bundle.module.url(forResource: "sample.textbundle", withExtension: nil)!
    let textBundle = try? TextBundleWrapper(fileWrapper: FileWrapper(url: url))

    XCTAssertEqual(textBundle?.info.version, 2)
    XCTAssertEqual(textBundle?.info.transient, true)
    XCTAssertEqual(textBundle?.info.type, "net.daringfireball.markdown")
    XCTAssertEqual(textBundle?.info.creatorIdentifier, "com.example.editor")

    let text = String(data: textBundle?.data ?? Data(), encoding: .utf8)
    XCTAssertEqual(text?.hasPrefix("# Textbundle Example"), true)
  }
}
