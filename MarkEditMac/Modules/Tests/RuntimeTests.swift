//
//  RuntimeTests.swift
//
//  Created by cyan on 6/28/23.
//

import XCTest
import WebKit
import AppKitExtensions

@MainActor
final class RuntimeTests: XCTestCase {
  func testExistenceOfDrawsBackground() {
    let configuration = WKWebViewConfiguration()
    testExistenceOfSelector(object: configuration, selector: "_drawsBackground")
  }

  func testExistenceOfDeveloperPreferences() {
    let preferences = WKWebViewConfiguration().preferences
    testExistenceOfSelector(object: preferences, selector: "_setDeveloperExtrasEnabled:")
    testExistenceOfSelector(object: preferences, selector: "_setWebSecurityEnabled:")

    let webView = WKWebView()
    testExistenceOfSelector(object: webView, selector: "_inspector")

    let inspector = webView.perform(sel_getUid("_inspector")).takeUnretainedValue()
    testExistenceOfSelector(object: inspector, selector: "show")
  }

  func testExistenceOfPerformancePreferences() {
    let configuration = WKWebViewConfiguration()
    testExistenceOfSelector(object: configuration, selector: "_setDelaysWebProcessLaunchUntilFirstLoad:")
    testExistenceOfSelector(object: configuration, selector: "_setWaitsForPaintAfterViewDidMoveToWindow:")

    let preferences = configuration.preferences
    testExistenceOfSelector(object: preferences, selector: "_setPageVisibilityBasedProcessSuppressionEnabled:")
    testExistenceOfSelector(object: preferences, selector: "_setHiddenPageDOMTimerThrottlingEnabled:")
    testExistenceOfSelector(object: preferences, selector: "_setHiddenPageDOMTimerThrottlingAutoIncreases:")
  }

  func testExistenceOfFeatureSPI() {
    testExistenceOfSelector(object: WKPreferences.self, selector: "_features")

    let preferences = WKPreferences()
    testExistenceOfSelector(object: preferences, selector: "_setEnabled:forFeature:")

    guard let features = (WKPreferences.self as AnyObject)
      .perform(sel_getUid("_features"))?.takeUnretainedValue() as? [AnyObject] else {
      return XCTFail("Failed to retrieve _features from WKPreferences")
    }

    let keys = Set(features.compactMap { $0.value(forKey: "key") as? String })
    for key in ["ServiceWorkersEnabled", "EncryptedMediaAPIEnabled", "LegacyEncryptedMediaAPIEnabled", "WebLocksAPIEnabled"] {
      XCTAssert(keys.contains(key), "Missing feature key: \(key)")
    }
  }

  func testExistenceOfBulkFeatureDisabling() {
    let preferences = WKPreferences()
    testExistenceOfSelector(object: preferences, selector: "_disableRichJavaScriptFeatures")
    testExistenceOfSelector(object: preferences, selector: "_disableMediaPlaybackRelatedFeatures")
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

  func testExistenceOfAppKitSearchField() {
    let window = NSWindow()
    window.makeKeyAndOrderFront(nil)

    let searchField = NSSearchField(frame: CGRect(x: 0, y: 0, width: 240, height: 40))
    window.contentView?.addSubview(searchField)

    let expectation = XCTestExpectation()
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      expectation.fulfill()
    }

    wait(for: [expectation])
    XCTAssertNotNil(searchField.modernBezelView)
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
    testExistenceOfClass(named: "_NSTitlebarDecorationView")
    testExistenceOfClass(named: "NSToolbarFullScreenWindow")
    testExistenceOfClass(named: "NSTitlebarView")
    testExistenceOfClass(named: "NSToolbarButton")
  }

  func testTitlebarDecorationViewSelector() {
    let window = NSWindow()
    window.makeKeyAndOrderFront(nil)

    if let view = window.titlebarDecorationView {
      testExistenceOfSelector(object: view, selector: "setDrawsBottomSeparator:")
    } else {
      XCTAssert(false, "Missing titlebarDecorationView")
    }
  }

  func testPrivateAccessibilityBundles() {
    let type: AnyClass? = NSObject.axbbmClass
    XCTAssertNotNil(type, "Missing AXBBundleManager")

    let object = type?.value(forKey: "defaultManager") as? AnyObject
    XCTAssertEqual(object?.responds(to: sel_getUid("loadAXBundles")), true, "Missing loadAXBundles")
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
