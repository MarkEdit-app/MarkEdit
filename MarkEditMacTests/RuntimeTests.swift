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

  func testPrivateAccessibilityBundles() {
    let type: AnyClass? = NSObject.axbbmClass
    XCTAssertNotNil(type, "Missing AXBBundleManager")

    let object = type?.value(forKey: "defaultManager") as? AnyObject
    XCTAssertEqual(object?.responds(to: sel_getUid("loadAXBundles")), true, "Missing loadAXBundles")
  }
}
