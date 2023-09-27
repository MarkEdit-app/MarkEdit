//
//  BundleTests.swift
//  MarkEditMacTests
//
//  Created by cyan on 2/2/23.
//

import XCTest

final class BundleTests: XCTestCase {
  func testExistenceOfAppIcon() {
    XCTAssertNotNil(NSImage(named: "AppIcon"), "Missing AppIcon from the main bundle")
  }
}
