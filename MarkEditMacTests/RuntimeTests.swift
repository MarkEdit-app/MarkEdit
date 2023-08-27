//
//  RuntimeTests.swift
//  MarkEditMacTests
//
//  Created by cyan on 6/28/23.
//

import XCTest
import WebKit
import AppKitExtensions

final class RuntimeTests: XCTestCase {
  func testExistenceOfAllowsInlinePredictions() {
    guard #available(macOS 14.0, *) else {
      return
    }

    #if compiler(<5.9)
      let configuration = WKWebViewConfiguration()
      configuration.setValue(true, forKey: "allowsInlinePredictions")
      testExistenceOfSelector(object: configuration, selector: "setAllowsInlinePredictions:")
    #endif
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

  func testRetrievingToolbarEffectView() {
    let window = NSWindow()
    window.makeKeyAndOrderFront(nil)
    XCTAssertNotNil(window.toolbarEffectView)
  }

  func testPrivateAppKitClasses() {
    testExistenceOfClass(named: "_NSKeyboardFocusClipView")
    testExistenceOfClass(named: "NSTitlebarView")
    testExistenceOfClass(named: "NSToolbarButton")
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
