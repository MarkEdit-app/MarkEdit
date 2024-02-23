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
  func testExistenceOfDrawsBackground() {
    let configuration = WKWebViewConfiguration()
    configuration.setValue(false, forKey: "drawsBackground")
    testExistenceOfSelector(object: configuration, selector: "_drawsBackground")
  }

  func testExistenceOfDeveloperExtras() {
    let preferences = WKWebViewConfiguration().preferences
    preferences.setValue(true, forKey: "developerExtrasEnabled")
    testExistenceOfSelector(object: preferences, selector: "_developerExtrasEnabled")
  }

  func testExistenceOfAutomaticInlineCompletion() {
    guard #available(macOS 14.0, *) else {
      return
    }

    let checker = NSSpellChecker.self
    testExistenceOfSelector(object: checker, selector: "isAutomaticInlineCompletionEnabled")
  }
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
