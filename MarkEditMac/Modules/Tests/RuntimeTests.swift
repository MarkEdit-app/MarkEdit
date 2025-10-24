//
//  RuntimeTests.swift
//
//  Created by cyan on 6/28/23.
//

import XCTest
import WebKit
import AppKitExtensions

final class RuntimeTests: XCTestCase {
  func testExistenceOfAppIcon() {
    guard let bundle = (Bundle.allBundles.first { $0.bundleURL.lastPathComponent == "MarkEdit.app" }) else {
      return XCTFail("Missing MarkEdit.app bundle to continue")
    }

    XCTAssertNotNil(bundle.image(forResource: "AppIcon"), "Missing AppIcon from the main bundle")
  }

  func testExistenceOfDrawsBackground() {
    let configuration = WKWebViewConfiguration()
    configuration.setValue(false, forKey: "drawsBackground")
    testExistenceOfSelector(object: configuration, selector: "_drawsBackground")
  }

  func testExistenceOfDeveloperPreferences() {
    let preferences = WKWebViewConfiguration().preferences
    preferences.setValue(true, forKey: "developerExtrasEnabled")
    testExistenceOfSelector(object: preferences, selector: "_developerExtrasEnabled")

    preferences.setValue(false, forKey: "webSecurityEnabled")
    testExistenceOfSelector(object: preferences, selector: "_webSecurityEnabled")

    let webView = WKWebView()
    testExistenceOfSelector(object: webView, selector: "_inspector")

    let inspector = webView.perform(sel_getUid("_inspector")).takeUnretainedValue()
    testExistenceOfSelector(object: inspector, selector: "show")
  }

  func testExistenceOfAutomaticInlineCompletion() {
    let checker = NSSpellChecker.self
    testExistenceOfSelector(object: checker, selector: "isAutomaticInlineCompletionEnabled")
  }

  func testExistenceOfAutomaticInlinePredictionBeingPresented() {
    let checker = NSSpellChecker.self
    testExistenceOfSelector(object: checker, selector: "isAutomaticInlinePredictionBeingPresented")
  }

  func testExistenceOfShowCompletionForCandidate() {
    let checker = NSSpellChecker.shared
    testExistenceOfSelector(object: checker, selector: "showCompletionForCandidate:selectedRange:offset:inString:rect:view:completionHandler:")
  }

  func testExistenceOfCancelCorrection() {
    let checker = NSSpellChecker.shared
    testExistenceOfSelector(object: checker, selector: "cancelCorrectionIndicatorForView:")
  }

  func testExistenceOfImageTintColor() {
    testExistenceOfSelector(object: NSImage(), selector: "_setTintColor:")
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
    XCTAssertNotNil(popover.value(forKey: "positioningView"))
  }

  func testRetrievingToolbarEffectView() {
    let window = NSWindow()
    window.makeKeyAndOrderFront(nil)
    XCTAssertNotNil(window.toolbarEffectView)
  }

  func testPrivateAppKitClasses() {
    testExistenceOfClass(named: "_NSKeyboardFocusClipView")
    testExistenceOfClass(named: "NSToolbarFullScreenWindow")
    testExistenceOfClass(named: "NSTitlebarView")
    testExistenceOfClass(named: "NSToolbarButton")
  }

  func testPrivateAccessibilityBundles() {
    let type: AnyClass? = NSObject.axbbmClass
    XCTAssertNotNil(type, "Missing AXBBundleManager")

    let object = type?.value(forKey: "defaultManager") as? AnyObject
    XCTAssertEqual(object?.responds(to: sel_getUid("loadAXBundles")), true, "Missing loadAXBundles")
  }

  func testPrivateWebKitClasses() {
    let type = NSObject.webKitScrollerClass as? NSObject.Type
    XCTAssertNotNil(type, "Missing WebScrollerImpDelegateMac")

    let object = type?.init()
    XCTAssertEqual(object?.responds(to: sel_getUid("convertRectToBacking:")), true, "Missing convertRectToBacking:")
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
