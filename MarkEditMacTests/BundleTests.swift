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

  func testExistenceOfEditorConfig() {
    guard let path = Bundle.main.url(forResource: "index", withExtension: "html") else {
      fatalError("Missing index.html")
    }

    guard let data = try? Data(contentsOf: path) else {
      fatalError("Failed to read index.html")
    }

    let html = String(data: data, encoding: .utf8)
    XCTAssertEqual(html?.contains("\"{{EDITOR_CONFIG}}\""), true, "Invalid index.html file")
  }
}
