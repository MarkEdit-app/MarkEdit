//
//  PasteboardTests.swift
//
//  Created by cyan on 2/2/23.
//

import AppKitExtensions
import XCTest

final class PasteboardTests: XCTestCase {
  func testOverwritePasteboard() {
    NSPasteboard.general.overwrite(string: "Hello, World!")
    XCTAssertEqual(NSPasteboard.general.string, "Hello, World!")
  }
}
