//
//  EditorUserAssetTests.swift
//
//  Created by cyan on 10/6/26.
//

import JavaScriptCore
import MarkEditCore
import XCTest

final class EditorUserAssetTests: XCTestCase {
  func testScriptBindingsAndScope() throws {
    let context = try XCTUnwrap(JSContext())
    context.evaluateScript("""
    var window = this;
    window.MarkEdit = { shared: true };
    window.__createScriptContext__ = path => {
      const api = { path };
      return { MarkEdit: api, require: () => ({ MarkEdit: api }) };
    };
    """)

    let url = URL(fileURLWithPath: "/scripts/it's\\a\nscript\u{2028}.js")
    for declaration in ["", "const { MarkEdit } = require('markedit-api');"] {
      context.evaluateScript(EditorUserAsset.script(for: url, contents: """
      \(declaration)
      exports.path = __FILE_PATH__;
      exports.api = MarkEdit;
      exports.required = require('markedit-api').MarkEdit;
      window.result = module.exports;
      """))

      XCTAssertNil(context.exception)
      XCTAssertEqual(context.evaluateScript("result.path")?.toString(), url.path(percentEncoded: false))
      XCTAssertEqual(context.evaluateScript("result.api.path")?.toString(), url.path(percentEncoded: false))
      XCTAssertEqual(context.evaluateScript("result.api === result.required")?.toBool(), true)
      XCTAssertEqual(context.evaluateScript("window.MarkEdit.shared")?.toBool(), true)
      XCTAssertEqual(context.evaluateScript("typeof module")?.toString(), "undefined")
    }
  }

  func testQuickLookWithoutRequire() throws {
    let context = try XCTUnwrap(JSContext())
    context.evaluateScript("""
    var window = this;
    window.__createScriptContext__ = () => ({ MarkEdit: {} });
    """)

    context.evaluateScript(EditorUserAsset.script(
      for: URL(fileURLWithPath: "/scripts/quicklook.js"),
      contents: "window.result = typeof require;"
    ))

    XCTAssertNil(context.exception)
    XCTAssertEqual(context.evaluateScript("result")?.toString(), "undefined")
  }
}
