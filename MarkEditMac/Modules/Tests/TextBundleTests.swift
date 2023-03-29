//
//  TextBundleTests.swift
//
//  Created by cyan on 3/23/23.
//

import TextBundle
import XCTest

final class TextBundleTests: XCTestCase {
  func testTextBundleParsing() {
    // swiftlint:disable:next force_unwrapping
    let url = Bundle.module.url(forResource: "sample.textbundle", withExtension: nil)!
    let textBundle = try? TextBundleWrapper(fileWrapper: FileWrapper(url: url))

    let textContent = String(data: textBundle?.data ?? Data(), encoding: .utf8)
    XCTAssertEqual(textContent?.hasPrefix("# Textbundle Example"), true)
  }
}
