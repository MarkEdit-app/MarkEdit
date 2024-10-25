//
//  RuntimeTests.swift
//  MarkEditMacTests
//
//  Created by cyan on 6/28/23.
//

@testable import MarkEdit
import XCTest

final class RuntimeTests: XCTestCase {
  func testExistenceOfAppIcon() {
    XCTAssertNotNil(NSImage(named: "AppIcon"), "Missing AppIcon from the main bundle")
  }
}
