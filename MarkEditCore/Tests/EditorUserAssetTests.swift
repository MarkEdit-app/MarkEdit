//
//  EditorUserAssetTests.swift
//
//  Created by cyan on 10/6/26.
//

import JavaScriptCore
import MarkEditCore
import WebKit
import XCTest

@MainActor
final class EditorUserAssetTests: XCTestCase {
  func testScriptBindingsAndScope() throws {
    let context = try makeContext()
    let url = URL(fileURLWithPath: "/scripts/it's\\a\nscript\u{2028}.js")
    for declaration in ["", "const { MarkEdit } = require('markedit-api');"] {
      let source = """
      \(declaration)
      exports.path = __FILE_PATH__;
      exports.api = MarkEdit;
      exports.required = require('markedit-api').MarkEdit;
      window.result = module.exports;
      window.deferred = () => MarkEdit.path;
      """

      for injection in injections(for: url, contents: source, capability: "private-token") {
        context.evaluateScript(injection)
        XCTAssertNil(context.exception)
      }

      XCTAssertEqual(context.evaluateScript("result.path")?.toString(), url.path(percentEncoded: false))
      XCTAssertEqual(context.evaluateScript("result.api.path")?.toString(), url.path(percentEncoded: false))
      XCTAssertEqual(context.evaluateScript("result.api === result.required")?.toBool(), true)
      XCTAssertEqual(context.evaluateScript("window.MarkEdit.shared")?.toBool(), true)
      XCTAssertEqual(context.evaluateScript("typeof module")?.toString(), "undefined")
      XCTAssertEqual(context.evaluateScript("deferred()")?.toString(), url.path(percentEncoded: false))
      XCTAssertEqual(context.evaluateScript("callbackSource.includes('private-token')")?.toBool(), false)
    }
  }

  func testQuickLookScriptCanInstallGlobalRequire() throws {
    let context = try XCTUnwrap(JSContext())
    context.evaluateScript("var window = this; window.MarkEdit = { shared: true };")
    let url = URL(fileURLWithPath: "/scripts/quicklook.js")
    let source = EditorUserAsset.script(for: url, contents: """
    window.requireBeforeShim = typeof require;
    (() => {
      const root = globalThis;
      if (typeof root.require === 'undefined') {
        const modules = {
          'markedit-api': { MarkEdit: root.MarkEdit },
          '@codemirror/view': { EditorView: { shim: true } },
        };
        root.require = name => modules[name];
      }
    })();
    const { MarkEdit } = require('markedit-api');
    const { EditorView } = require('@codemirror/view');
    exports.api = MarkEdit;
    exports.view = EditorView;
    exports.path = __FILE_PATH__;
    window.result = module.exports;
    window.deferred = () => require('@codemirror/view');
    """)

    context.evaluateScript(source)
    XCTAssertNil(context.exception)
    XCTAssertEqual(context.evaluateScript("requireBeforeShim")?.toString(), "undefined")
    XCTAssertEqual(context.evaluateScript("result.api === window.MarkEdit")?.toBool(), true)
    XCTAssertEqual(context.evaluateScript("result.view.shim")?.toBool(), true)
    XCTAssertEqual(context.evaluateScript("result.path")?.toString(), url.path(percentEncoded: false))
    XCTAssertEqual(context.evaluateScript("deferred().EditorView === result.view")?.toBool(), true)
    XCTAssertEqual(context.evaluateScript("typeof module")?.toString(), "undefined")

    let next = EditorUserAsset.script(for: URL(fileURLWithPath: "/scripts/next.js"), contents: """
    window.nextView = require('@codemirror/view').EditorView;
    """)
    context.evaluateScript(next)
    XCTAssertNil(context.exception)
    XCTAssertEqual(context.evaluateScript("nextView === result.view")?.toBool(), true)
  }

  func testBootstrapKeepsSourcesSeparateFromCapabilities() throws {
    let path = "/scripts/'\\\n\u{2028}escape.js"
    let content = "}); window.escaped = true; // </script>\n'\"\\\u{2029}"
    let sources = injections(for: URL(fileURLWithPath: path), contents: content, capability: "private-token")
    XCTAssertEqual(sources.count, 2)
    XCTAssertFalse(sources[0].contains(content))
    XCTAssertTrue(sources[1].contains(content))
    XCTAssertFalse(sources[1].contains("new Function"))

    let context = try XCTUnwrap(JSContext())
    context.evaluateScript("var __prepareScriptContexts__ = contexts => { globalThis.contexts = contexts; };")
    context.evaluateScript(sources[0])
    XCTAssertNil(context.exception)
    XCTAssertEqual(context.evaluateScript("contexts[0].path")?.toString(), path)
    XCTAssertEqual(context.evaluateScript("contexts[0].capability")?.toString(), "private-token")
    XCTAssertEqual(context.evaluateScript("typeof escaped")?.toString(), "undefined")
  }

  func testMalformedScriptDoesNotBlockLaterInjections() throws {
    let context = try makeContext()
    let scripts = EditorUserAsset.contextualScripts(for: [
      ("/bad.js", EditorUserAsset.script(for: URL(fileURLWithPath: "/bad.js"), contents: "const ="), "bad-token"),
      ("/good.js", EditorUserAsset.script(for: URL(fileURLWithPath: "/good.js"), contents: "window.lastScriptRan = true;"), "good-token"),
    ])

    let sources = scripts.map(\.source)
    context.evaluateScript(sources[0])
    XCTAssertNil(context.exception)

    context.evaluateScript(sources[1])
    XCTAssertNotNil(context.exception)

    context.exception = nil
    context.evaluateScript(sources[2])
    XCTAssertNil(context.exception)
    XCTAssertEqual(context.evaluateScript("lastScriptRan")?.toBool(), true)
  }

  private func makeContext() throws -> JSContext {
    let context = try XCTUnwrap(JSContext())
    context.evaluateScript("""
    var window = this;
    window.MarkEdit = { shared: true };
    window.require = () => {};
    window.__prepareScriptContexts__ = scripts => {
      const contexts = new Map(scripts.map(script => [script.capability ?? script.path, { path: script.path }]));
      window.__runScriptWithContext__ = function(key, execute) {
        'use strict';
        const api = contexts.get(key);
        contexts.delete(key);
        window.callbackSource = execute.toString();
        execute(api, window.require ? () => ({ MarkEdit: api }) : undefined);
      };
    };
    """)

    return context
  }

  private func injections(for url: URL, contents: String, capability: String? = nil) -> [String] {
    let scripts = EditorUserAsset.contextualScripts(for: [
      (url.path(percentEncoded: false), EditorUserAsset.script(for: url, contents: contents), capability),
    ])

    for script in scripts {
      XCTAssertEqual(script.injectionTime, .atDocumentEnd)
      XCTAssertTrue(script.isForMainFrameOnly)
    }

    return scripts.map(\.source)
  }
}
