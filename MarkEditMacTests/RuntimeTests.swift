//
//  RuntimeTests.swift
//  MarkEditMacTests
//
//  Created by cyan on 6/28/23.
//

import XCTest
import WebKit

final class RuntimeTests: XCTestCase {
  func testExistenceOfAllowsInlinePredictions() {
    guard #available(macOS 14.0, *) else {
      return
    }

    // [macOS 14] Remove after WebKit exposes this as public
    let configuration = WKWebViewConfiguration()
    configuration.setValue(true, forKey: "allowsInlinePredictions")
    testExistenceOfSelector(object: configuration, selector: "setAllowsInlinePredictions:")
  }

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

  func testExistenceOfCancelCorrection() {
    let checker = NSSpellChecker()
    testExistenceOfSelector(object: checker, selector: "cancelCorrectionIndicatorForView:")
  }

  func testRetrievingPopover() {
    class ContentViewController: NSViewController {
      override func loadView() {
        view = NSView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
      }
    }

    let window = NSWindow()
    window.makeKeyAndOrderFront(nil)

    guard let contentView = window.contentView else {
      XCTAssert(false, "Missing contentView in NSWindow")
      return
    }

    let popover = NSPopover()
    popover.contentViewController = ContentViewController(nibName: nil, bundle: nil)
    popover.show(
      relativeTo: CGRect(x: 0, y: 0, width: 1, height: 1),
      of: contentView,
      preferredEdge: .maxX
    )

    let expectation = XCTestExpectation()
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      expectation.fulfill()
    }

    wait(for: [expectation])
    XCTAssertNotNil(popover.contentViewController?.view.window?.value(forKey: "_popover"))
  }
}

// MARK: - Private

private extension RuntimeTests {
  func testExistenceOfSelector(object: AnyObject, selector: String) {
    XCTAssert(object.responds(to: sel_getUid(selector)), "Missing \(selector) in \(object.self)")
  }
}
