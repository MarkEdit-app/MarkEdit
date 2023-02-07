//
//  DataDetectorTests.swift
//
//  Created by cyan on 2/2/23.
//

import AppKitExtensions
import XCTest

final class DataDetectorTests: XCTestCase {
  func testExtractURL() {
    let url = NSDataDetector.extractURL(from: "Check it out https://markedit.app.")
    XCTAssertEqual(url, "https://markedit.app")
  }
}
