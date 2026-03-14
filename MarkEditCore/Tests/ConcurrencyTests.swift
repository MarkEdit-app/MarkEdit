//
//  ConcurrencyTests.swift
//

import MarkEditCore
import XCTest

/**
 Regression tests for Swift 6 strict-concurrency conformances added during
 the macOS 26 crash fix.

 `AppRuntimeConfig.Definition` wraps `EditorIndentBehavior` and must be
 `Sendable` so it can be decoded and shipped across task boundaries (e.g.
 from a URLSession background task to the main actor).  Before the fix,
 `EditorIndentBehavior` lacked `Sendable`, making `Definition` non-Sendable
 and generating a Swift 6 compiler error in the strict-concurrency pass.
 */
final class ConcurrencyTests: XCTestCase {

  // MARK: - EditorIndentBehavior.Sendable

  func testEditorIndentBehaviorSendableAcrossTaskBoundary() async {
    // If EditorIndentBehavior were not Sendable this line would be a
    // Swift 6 compile error: "sending value of non-Sendable type across
    // actor boundary".
    let value = EditorIndentBehavior.paragraph

    let received = await Task.detached { value }.value

    XCTAssertEqual(received, value)
  }

  func testAllEditorIndentBehaviorCasesRoundTripAcrossTasks() async {
    for original in [EditorIndentBehavior.never, .paragraph, .line] {
      let received = await Task.detached { original }.value
      XCTAssertEqual(received, original, "Case \(original) should survive task boundary")
    }
  }

  // MARK: - EditorIndentBehavior.Codable (sanity check for AppRuntimeConfig.Definition)

  func testEditorIndentBehaviorCodableRoundTrip() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    for value in [EditorIndentBehavior.never, .paragraph, .line] {
      let data = try encoder.encode(value)
      let decoded = try decoder.decode(EditorIndentBehavior.self, from: data)
      XCTAssertEqual(decoded, value)
    }
  }
}
