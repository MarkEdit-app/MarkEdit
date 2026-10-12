//
//  DocumentSnapshotTests.swift
//
//  Created by cyan on 10/11/26.
//

import WebKit
import XCTest
@testable import MarkEditKit

@MainActor
final class DocumentSnapshotTests: XCTestCase {
  func testOutlineBridgeOmitsCachedTextAndDecodesFreshText() async throws {
    let webView = WKWebView()
    _ = try await webView.evaluateJavaScript("""
      window.webModules = {
        toc: {
          getDocumentOutline({ knownRevision }) {
            return {
              revision: 'current',
              text: knownRevision === 'current' ? undefined : '# Plan\\r\\nBody',
              headings: []
            };
          }
        }
      };
      void 0;
      """)

    let bridge = WebBridgeTableOfContents(webView: webView)
    let snapshot = try await bridge.getDocumentOutline(knownRevision: nil)
    XCTAssertEqual(snapshot.text, "# Plan\r\nBody")
    XCTAssertEqual(snapshot.revision, "current")

    let cached = try await bridge.getDocumentOutline(knownRevision: snapshot.revision)
    XCTAssertEqual(cached.revision, snapshot.revision)
    XCTAssertNil(cached.text)
    for revision in [nil, "outdated"] {
      let fresh = try await bridge.getDocumentOutline(knownRevision: revision)
      XCTAssertEqual(fresh.text, snapshot.text)
      XCTAssertEqual(fresh.revision, snapshot.revision)
    }
  }
}
