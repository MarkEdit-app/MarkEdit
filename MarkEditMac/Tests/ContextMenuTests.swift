//
//  ContextMenuTests.swift
//
//  Created by cyan on 10/13/26.
//

import AppKit
import MarkEditKit
import XCTest
@testable import MarkEdit

@MainActor
final class ContextMenuTests: XCTestCase {
  func testContextMenuAPIHighlightsRequestedItem() async throws {
    let window = NSPanel(
      contentRect: NSRect(x: 20, y: 20, width: 600, height: 400),
      styleMask: [.titled, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )

    let editor = EditorViewController(preloadDelay: 60)
    window.contentViewController = editor
    window.makeKeyAndOrderFront(nil)
    defer { window.close() }

    let api = EditorModuleAPI(delegate: editor)
    let cases: [(index: Int?, expected: Int?)] = [
      (nil, nil), (0, 0), (2, 2), (1, nil), (3, nil), (-1, nil), (100, nil),
    ]

    for testCase in cases {
      var parameters: [String: Any] = [
        "items": [
          ["title": "First", "separator": false, "actionID": "first"],
          ["separator": true],
          ["title": "Last", "separator": false, "actionID": "last"],
          ["title": "Disabled", "separator": false],
        ],
        "location": ["x": 20, "y": 20],
      ]

      parameters["highlightedIndex"] = testCase.index
      try await checkHighlight(in: editor, expectedIndex: testCase.expected) {
        let result = await api.bridge.invoke(
          method: "showContextMenu",
          parameters: try JSONSerialization.data(withJSONObject: parameters)
        )

        _ = try XCTUnwrap(result).get()
      }
    }
  }

  func testContextMenuAwaitsJavaScriptItemState() async throws {
    let window = NSPanel(
      contentRect: NSRect(x: 20, y: 20, width: 600, height: 400),
      styleMask: [.titled, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )

    let editor = EditorViewController()
    window.contentViewController = editor
    window.makeKeyAndOrderFront(nil)
    defer { window.close() }

    let deadline = ContinuousClock.now + .seconds(10)
    while !editor.hasFinishedLoading, ContinuousClock.now < deadline {
      try await Task.sleep(for: .milliseconds(10))
    }

    XCTAssertTrue(editor.hasFinishedLoading)
    _ = try await editor.bridge.core.resetEditor(text: "Test", selectionRange: nil, documentChanged: true)

    let cases: [(stateBody: String, expected: Int?)] = [
      ("return {};", 0),
      ("return { isEnabled: true };", 0),
      ("return { isEnabled: false };", nil),
      ("throw new Error('Expected state failure');", nil),
    ]

    for testCase in cases {
      try await checkHighlight(in: editor, expectedIndex: testCase.expected) {
        _ = try await editor.webView.evaluateJavaScript("""
          MarkEdit.showContextMenu([
            { title: 'First', action() {}, state() { \(testCase.stateBody) } }
          ], { x: 20, y: 20 }, { highlightedIndex: 0 });
          true;
          """)
      }
    }
  }

  private func checkHighlight(
    in editor: EditorViewController,
    expectedIndex: Int?,
    showMenu: () async throws -> Void
  ) async throws {
    let checked = expectation(description: "Checked context menu highlight")
    let timer = Timer(
      timeInterval: 0.1,
      target: self,
      selector: #selector(checkContextMenuHighlight(_:)),
      userInfo: (editor, expectedIndex, checked),
      repeats: false
    )

    RunLoop.main.add(timer, forMode: .eventTracking)
    defer { timer.invalidate() }

    try await showMenu()
    await fulfillment(of: [checked], timeout: 2)
  }

  @objc private func checkContextMenuHighlight(_ timer: Timer) {
    guard let (editor, expectedIndex, checked) = timer.userInfo as? (EditorViewController, Int?, XCTestExpectation),
          let menu = editor.presentedMenu else {
      XCTFail("Missing context menu")
      return
    }

    if let expectedIndex {
      XCTAssertIdentical(menu.highlightedItem, menu.items[expectedIndex])
    } else {
      XCTAssertNil(menu.highlightedItem)
    }

    checked.fulfill()
    menu.cancelTracking()
  }
}
