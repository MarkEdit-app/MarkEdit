//
//  EditorIndexHtmlTests.swift
//
//  Created by cyan on 10/17/26.
//

import Foundation
import JavaScriptCore
@testable import MarkEditCore
import XCTest

final class EditorIndexHtmlTests: XCTestCase {
  func testMissingSettings() {
    XCTAssertNil(EditorIndexHtml.userSettings(at: nil))
    let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    XCTAssertNil(EditorIndexHtml.userSettings(at: url))
    XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
  }

  func testSettingsObject() throws {
    try withSettingsFile { url in
      let source = """
      {"preview.enabled": true, "nested": {"size": 14}, "items": [1, "two"], "optional": null}
      """
      try Data(source.utf8).write(to: url)

      let json = EditorIndexHtml.userSettings(at: url) ?? "{}"
      let settings = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])
      XCTAssertEqual(settings["preview.enabled"] as? Bool, true)
      XCTAssertEqual(settings["nested"] as? [String: Int], ["size": 14])
      XCTAssertEqual((settings["items"] as? [Any])?.count, 2)
      XCTAssertTrue(settings["optional"] is NSNull)
      XCTAssertEqual(try String(contentsOf: url, encoding: .utf8), source)
    }
  }

  func testInvalidSettings() throws {
    try withSettingsFile { url in
      for source in ["", "{invalid}", "[]", "null", "true", "42", "\"text\""] {
        try Data(source.utf8).write(to: url)
        XCTAssertNil(EditorIndexHtml.userSettings(at: url), source)
      }
    }
  }

  func testUnreadableSettings() throws {
    try withSettingsFile { url in
      try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
      XCTAssertNil(EditorIndexHtml.userSettings(at: url))
    }
  }

  func testSettingsAreReloaded() throws {
    try withSettingsFile { url in
      for value in [1, 2] {
        try Data("{\"value\": \(value)}".utf8).write(to: url, options: .atomic)
        let json = EditorIndexHtml.userSettings(at: url) ?? "{}"
        let settings = try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Int]
        XCTAssertEqual(settings, ["value": value])
      }

      try FileManager.default.removeItem(at: url)
      XCTAssertNil(EditorIndexHtml.userSettings(at: url))
    }
  }

  func testSettingsPreserveStringValues() throws {
    try withSettingsFile { url in
      let value = "</script><script>alert('test')</script><!--<script>\u{2028}\u{2029}"
      let data = try JSONSerialization.data(withJSONObject: ["value": value])
      try data.write(to: url)

      let json = EditorIndexHtml.userSettings(at: url) ?? "{}"
      let context = try XCTUnwrap(JSContext())
      context.evaluateScript("var MarkEdit = { userSettings: \(json) };")
      XCTAssertNil(context.exception)
      XCTAssertEqual(context.evaluateScript("MarkEdit.userSettings.value")?.toString(), value)
    }
  }

  private func withSettingsFile(_ body: (URL) throws -> Void) throws {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)

    defer {
      do {
        try FileManager.default.removeItem(at: directory)
      } catch {
        XCTFail("Failed to remove temporary settings directory: \(error)")
      }
    }

    try body(directory.appending(path: "settings.json"))
  }
}
