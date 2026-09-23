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

  func testColorMixComputedStyle() async throws {
    let webView = WKWebView()
    let loaded = expectation(description: "Test document loaded")
    let navigationDelegate = TestNavigationDelegate(loaded: loaded)
    webView.navigationDelegate = navigationDelegate
    defer { webView.navigationDelegate = nil }

    webView.loadHTMLString("<!doctype html><html><body></body></html>", baseURL: nil)
    await fulfillment(of: [loaded], timeout: 10)
    try XCTUnwrap(navigationDelegate.result).get()

    let result = try await webView.evaluateJavaScript("""
      const element = document.createElement('div');
      element.style.backgroundColor = 'color-mix(in srgb, rgb(255, 255, 255) 40%, transparent)';
      document.body.append(element);
      const color = getComputedStyle(element).backgroundColor;

      const canvas = document.createElement('canvas');
      canvas.width = 1;
      canvas.height = 1;

      // Avoid GPU-backed readback failures on virtualized macOS runners
      const context = canvas.getContext('2d', { willReadFrequently: true });
      context.fillStyle = color;
      context.fillRect(0, 0, 1, 1);
      [...context.getImageData(0, 0, 1, 1).data].join(',');
      """) as? String

    XCTAssertEqual(result, "255,255,255,102")
  }

  func testExistenceOfDeveloperPreferences() {
    let configuration = WKWebViewConfiguration()
    testExistenceOfSelector(object: configuration, selector: "_setCORSDisablingPatterns:")
    testExistenceOfSelector(object: configuration.preferences, selector: "_setDeveloperExtrasEnabled:")

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

    let webView = WKWebView()
    testExistenceOfSelector(object: webView, selector: "_setWindowOcclusionDetectionEnabled:")
  }

  func testExistenceOfNetworkProcessIdentifier() {
    let dataStore = WKWebsiteDataStore.default()
    dataStore.launchNetworkProcess()
    XCTAssertTrue(dataStore.responds(to: sel_getUid("_networkProcessIdentifier")))
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

  func testExistenceOfAppKitSearchField() async throws {
    if #available(macOS 27.0, *) {
      throw XCTSkip("[macOS 27] Revisit this later")
    }

    let window = NSWindow()
    window.makeKeyAndOrderFront(nil)

    let searchField = NSSearchField(frame: CGRect(x: 0, y: 0, width: 240, height: 40))
    window.contentView?.addSubview(searchField)

    try await Task.sleep(for: .seconds(1))
    XCTAssertNotNil(searchField.modernBezelView)
  }

  func testExistenceOfMinimumSearchFieldWidth() {
    let item = NSSearchToolbarItem()
    testExistenceOfSelector(object: item, selector: "minimumWidthForSearchFieldRepresentation")
    testExistenceOfSelector(object: item, selector: "setMinimumWidthForSearchFieldRepresentation:")

    item.minimumSearchFieldWidth = 500
    XCTAssertEqual(item.minimumSearchFieldWidth, 500)
  }

  func testRetrievingPopover() async throws {
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

    try await Task.sleep(for: .seconds(1))
    XCTAssertNotNil(popover.contentViewController?.view.window?.value(forKey: "_popover"))
    XCTAssertNotNil(popover.value(forKey: "positioningView"))
  }

  func testRetrievingTitlebarPrivateViews() {
    let window = NSWindow()
    window.makeKeyAndOrderFront(nil)

    XCTAssertNotNil(window.titlebarView)
    XCTAssertNotNil(window.titlebarDecorationView)
    XCTAssertNotNil(window.titlebarBackgroundView)
    XCTAssertNotNil(window.titlebarDocumentTitleView)
  }

  func testPrivateAppKitClasses() {
    testExistenceOfClass(named: "_NSKeyboardFocusClipView")
    testExistenceOfClass(named: "_NSTitlebarDecorationView")
    testExistenceOfClass(named: "NSToolbarFullScreenWindow")
    testExistenceOfClass(named: "NSTitlebarContainerView")
    testExistenceOfClass(named: "NSTitlebarBackgroundView")
    testExistenceOfClass(named: "NSTitlebarView")
    testExistenceOfClass(named: "NSToolbarButton")
    testExistenceOfClass(named: "NSThemeDocumentButton")
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

  func testExistenceOfShowWritingTools() {
    let webView = WKWebView()
    testExistenceOfSelector(object: webView, selector: "_showWritingTools")
  }

  func testExistenceOfStandardWritingToolsMenuItem() {
    let item = NSMenuItem.systemWritingToolsItem
    XCTAssertNotNil(item)
  }

  func testEnsureMenuImageVisibility() {
    let item = NSMenuItem(title: "Test")
    let image = NSImage(size: CGSize(width: 16, height: 16))
    item.image = image

    if #available(macOS 27.0, *) {
      item.preferredImageVisibility = .hidden
    }

    item.ensureImageVisibility()
    XCTAssertIdentical(item.image, image)

    if #available(macOS 27.0, *) {
      XCTAssertEqual(item.preferredImageVisibility, .visible)
    }
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

@MainActor
private final class TestNavigationDelegate: NSObject, WKNavigationDelegate {
  let loaded: XCTestExpectation
  private(set) var result: Result<Void, Error>?

  init(loaded: XCTestExpectation) {
    self.loaded = loaded
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
    result = .success(())
    loaded.fulfill()
  }

  func webView(_ webView: WKWebView, didFail navigation: WKNavigation?, withError error: Error) {
    result = .failure(error)
    loaded.fulfill()
  }

  func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation?, withError error: Error) {
    result = .failure(error)
    loaded.fulfill()
  }
}
