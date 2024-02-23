//
//  RuntimeTests.swift
//  MarkEditMacTests
//
//  Created by cyan on 6/28/23.
//

@testable import MarkEdit
import XCTest
import WebKit
import AppKitExtensions

final class RuntimeTests: XCTestCase {
  //
}

// MARK: - Private

private extension RuntimeTests {
  func testExistenceOfSelector(object: AnyObject, selector: String) {
    XCTAssert(object.responds(to: sel_getUid(selector)), "Missing \(selector) in \(object.self)")
  }

  func testExistenceOfClass(named className: String) {
    XCTAssertNotNil(NSClassFromString(className), "Class \(className) cannot be found")
  }
}
