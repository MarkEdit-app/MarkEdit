//
//  QuickSearchWindowTests.swift
//
//  Created by cyan on 10/11/26.
//

import AppKit
import XCTest
@testable import QuickSearchUI

@MainActor
final class QuickSearchWindowTests: XCTestCase {
  func testAcceptedTextDismissesWindow() throws {
    var submittedText: String?
    let window = makeWindow { text in
      submittedText = text
      return true
    }

    defer { window.orderOut(nil) }
    let field = try textField(in: window)
    field.stringValue = " path/to/Notes.md "
    window.makeKeyAndOrderFront(nil)

    XCTAssertTrue(try submit(window))
    XCTAssertEqual(submittedText, " path/to/Notes.md ")
    XCTAssertFalse(window.isVisible)
  }

  func testRejectedTextStaysVisibleAndSelected() throws {
    var submittedText: String?
    let window = makeWindow { text in
      submittedText = text
      return false
    }

    defer { window.orderOut(nil) }
    let field = try textField(in: window)
    field.stringValue = "invalid"
    window.makeKeyAndOrderFront(nil)
    window.makeFirstResponder(field)
    field.currentEditor()?.selectedRange = NSRange(location: 7, length: 0)

    XCTAssertTrue(try submit(window))
    XCTAssertEqual(submittedText, "invalid")
    XCTAssertTrue(window.isVisible)
    XCTAssertEqual(field.stringValue, "invalid")
    XCTAssertEqual(field.currentEditor()?.selectedRange, NSRange(location: 0, length: 7))
  }
}

private extension QuickSearchWindowTests {
  func makeWindow(handler: @escaping (String) -> Bool) -> QuickSearchWindow {
    QuickSearchWindow(
      effectViewType: NSVisualEffectView.self,
      relativeTo: CGRect(x: 0, y: 0, width: 800, height: 600),
      placeholder: "Open",
      accessibilityHelp: "Enter a value",
      iconName: "magnifyingglass",
      handler: handler
    )
  }

  func textField(in window: QuickSearchWindow) throws -> NSTextField {
    let view = try XCTUnwrap(window.contentView as? QuickSearchView)
    return try XCTUnwrap(view.subviews.compactMap { $0 as? NSTextField }.first)
  }

  func submit(_ window: QuickSearchWindow) throws -> Bool {
    let view = try XCTUnwrap(window.contentView as? QuickSearchView)
    return view.control(
      try textField(in: window),
      textView: NSTextView(),
      doCommandBy: #selector(NSResponder.insertNewline(_:))
    )
  }
}
