//
//  ExtensionToolbarTests.swift
//
//  Created by cyan on 11/18/26.
//

import AppKit
import MarkEditKit
import XCTest
import WebKit
@testable import MarkEdit

@MainActor
final class ExtensionToolbarTests: XCTestCase {
  func testAutomaticPlacementFitsAndRespectsRemoval() throws {
    let spec = segmentedSpec(
      titles: [
        "Markdown Source",
        "Preview (Side-by-Side)",
        "Preview (Overlay)",
        "Mixed (Syntax Hidden)",
      ]
    )

    let itemID = ExtensionToolbarController.identifier(for: spec.id)
    let editor = EditorViewController(preloadDelay: 60)
    let toolbar = makeToolbar(editor, autosaves: true)
    let window = try XCTUnwrap(editor.view.window)
    let originalItems: [NSToolbarItem.Identifier] = [.formatHeaders, .toggleBold, .toggleItalic, .toggleList]
    toolbar.itemIdentifiers = originalItems

    var paletteOnly = segmentedSpec()
    paletteOnly.initialPlacement = .customization
    editor.addToolbarItems([spec, paletteOnly])
    window.orderFront(nil)
    window.contentView?.superview?.layoutSubtreeIfNeeded()
    XCTAssertEqual(toolbar.visibleItems?.map(\.itemIdentifier), [itemID] + originalItems)
    XCTAssertTrue(editor.toolbarAllowedItemIdentifiers(toolbar).contains(
      ExtensionToolbarController.identifier(for: paletteOnly.id)
    ))

    toolbar.removeItem(at: 0)
    editor.configureToolbar()
    XCTAssertEqual(toolbar.itemIdentifiers, originalItems)

    let reopened = EditorViewController(preloadDelay: 60)
    paletteOnly.initialPlacement = .toolbar
    reopened.addToolbarItems([spec, paletteOnly])

    let restored = makeToolbar(reopened, id: toolbar.identifier, autosaves: true)
    reopened.configureToolbar()
    XCTAssertEqual(restored.itemIdentifiers, originalItems)
    XCTAssertTrue(reopened.toolbarAllowedItemIdentifiers(restored).contains(itemID))
  }

  func testCopiedOverflowMenuKeepsIconStateAndActions() async throws {
    let editor = try await makeSegmentedEditor()
    let spec = try XCTUnwrap(editor.userDefinedToolbarItems.first)
    let group = try XCTUnwrap(ExtensionToolbarController.makeToolbarItem(spec: spec, editor: editor) as? NSToolbarItemGroup)

    try await waitUntil { group.isSelected(at: 0) }
    let representation = try XCTUnwrap(group.menuFormRepresentation?.copy() as? NSMenuItem)
    XCTAssertNotNil(representation.image)

    let menu = try XCTUnwrap(representation.submenu)
    _ = try await editor.webView.evaluateJavaScript("window.mode = 1; window.disabled = true; true;")
    menu.delegate?.menuNeedsUpdate?(menu)
    XCTAssertTrue(menu.items.allSatisfy(\.isEnabled))
    XCTAssertEqual(menu.items[0].state, .on)

    let source = menu.items[0]
    XCTAssertTrue(NSApp.sendAction(try XCTUnwrap(source.action), to: source.target, from: source))
    try await waitUntil { group.isSelected(at: 0) && !group.subitems[1].isEnabled }
    let mode = try await editor.webView.evaluateJavaScript("window.mode") as? Int
    XCTAssertEqual(mode, 0)
  }

  func testCachedDefaultsBindWithoutReplacingOtherWindowItems() async throws {
    let spec = segmentedSpec()
    let first = EditorViewController(preloadDelay: 60)
    let second = EditorViewController(preloadDelay: 60)
    let firstToolbar = makeToolbar(first)
    firstToolbar.itemIdentifiers = []
    let other = segmentedSpec()
    ExtensionToolbarController.cacheDefaults([other])
    first.addToolbarItems([spec])
    ExtensionToolbarController.cachedDefaults = AppPreferences.Window.extensionToolbarCache
    XCTAssertNotNil(ExtensionToolbarController.cachedDefaults[other.id])

    let original = try XCTUnwrap(firstToolbar.items.first as? NSToolbarItemGroup)
    let originalController = try XCTUnwrap(original.extensionToolbarController)
    original.isEnabled = true
    original.setSelected(true, at: 1)
    original.subitems.forEach { $0.isEnabled = true }

    let removedID = ExtensionToolbarController.identifier(for: UUID().uuidString)
    firstToolbar.insertItem(withItemIdentifier: removedID, at: firstToolbar.items.count)

    let webView = DeferredWebView()
    second.bridge = WebModuleBridge(webView: webView)

    let secondToolbar = makeToolbar(second, id: firstToolbar.identifier)
    let cached = try XCTUnwrap(secondToolbar.items.first as? NSToolbarItemGroup)
    let cachedImage = try XCTUnwrap(cached.image)
    XCTAssertEqual(cached.label, spec.title)
    XCTAssertEqual(cached.subitems.map(\.label), ["Source", "Preview"])
    XCTAssertFalse(cached.isEnabled)
    XCTAssertFalse(cached.isSelected(at: 1))
    XCTAssertNil(cached.extensionToolbarController)
    XCTAssertTrue(webView.requests.isEmpty)
    XCTAssertTrue(secondToolbar.itemIdentifiers.contains(removedID))

    second.addToolbarItems([spec])
    XCTAssertIdentical(secondToolbar.items.first, cached)
    XCTAssertIdentical(cached.image, cachedImage)
    XCTAssertFalse(cached.isEnabled)

    second.hasFinishedLoading = true
    XCTAssertEqual(secondToolbar.itemIdentifiers, [original.itemIdentifier])
    XCTAssertFalse(second.toolbarAllowedItemIdentifiers(secondToolbar).contains(removedID))
    XCTAssertIdentical(firstToolbar.items.first, original)
    XCTAssertIdentical(original.extensionToolbarController, originalController)
    XCTAssertTrue(original.isSelected(at: 1))
    XCTAssertTrue(original.subitems.allSatisfy(\.isEnabled))

    try await waitUntil { webView.requests.count == 1 }
    let states = [
      ["isSelected": false, "isEnabled": false],
      ["isSelected": true, "isEnabled": true],
    ]

    webView.requests.removeFirst().completion?(states, nil)
    try await waitUntil { cached.isEnabled }
    XCTAssertTrue(cached.isSelected(at: 1))
    XCTAssertFalse(cached.subitems[0].isEnabled)
    XCTAssertTrue(cached.subitems[1].isEnabled)

    var changed = spec
    changed.segments?.removeLast()

    let third = EditorViewController(preloadDelay: 60)
    let thirdToolbar = makeToolbar(third, id: firstToolbar.identifier)
    third.addToolbarItems([changed])
    XCTAssertEqual((thirdToolbar.items.first as? NSToolbarItemGroup)?.subitems.count, 1)

    let emptyEditor = EditorViewController(preloadDelay: 60)
    let emptyToolbar = makeToolbar(emptyEditor)
    emptyToolbar.itemIdentifiers = [removedID]
    emptyEditor.hasFinishedLoading = true
    XCTAssertTrue(emptyToolbar.items.isEmpty)
  }

  func testInsertionNotificationContainsActualGroupAndBindsActions() async throws {
    let editor = try await makeSegmentedEditor()
    let toolbar = makeToolbar(editor)
    toolbar.itemIdentifiers = []

    let observer = ToolbarInsertionObserver()
    NotificationCenter.default.addObserver(
      observer,
      selector: #selector(ToolbarInsertionObserver.capture(_:)),
      name: NSToolbar.willAddItemNotification,
      object: toolbar
    )

    defer {
      NotificationCenter.default.removeObserver(observer)
    }

    toolbar.insertItem(withItemIdentifier: ExtensionToolbarController.identifier(for: "test.mode"), at: 0)
    let notification = try XCTUnwrap(observer.notification)
    XCTAssertIdentical(notification.object as? NSToolbar, toolbar)

    let group = try XCTUnwrap(notification.userInfo?[NSToolbarUserInfoKey.itemKey.rawValue] as? NSToolbarItemGroup)
    XCTAssertIdentical(group, toolbar.items.first)
    try await waitUntil { group.subitems.allSatisfy(\.isEnabled) }
    group.selectedIndex = 1
    XCTAssertTrue(NSApp.sendAction(try XCTUnwrap(group.action), to: group.target, from: group))

    let mode = try await editor.webView.evaluateJavaScript("window.mode") as? Int
    XCTAssertEqual(mode, 1)
  }

  func testOverflowDoesNotActAfterItsStateReadIsInvalidated() async throws {
    let editor = EditorViewController(preloadDelay: 60)
    let webView = DeferredWebView()
    editor.bridge = WebModuleBridge(webView: webView)

    let spec = segmentedSpec()
    let group = try XCTUnwrap(ExtensionToolbarController.makeToolbarItem(spec: spec, editor: editor) as? NSToolbarItemGroup)
    let controller = try XCTUnwrap(group.extensionToolbarController)
    let enabled = [["isSelected": true, "isEnabled": true], ["isSelected": false, "isEnabled": true]]
    try await waitUntil { webView.requests.count == 1 }
    webView.requests.removeFirst().completion?(enabled, nil)

    try await waitUntil { group.isSelected(at: 0) }
    let choice = try XCTUnwrap(group.menuFormRepresentation?.submenu?.items[1])
    XCTAssertTrue(NSApp.sendAction(try XCTUnwrap(choice.action), to: choice.target, from: choice))

    try await waitUntil { webView.requests.count == 1 }
    controller.invalidateState()
    webView.requests.removeFirst().completion?(enabled, nil)

    try await waitUntil { webView.requests.count == 1 }
    let next = webView.requests.removeFirst()
    XCTAssertTrue(next.script.contains("getMenuItemStates"), "Must refresh, not dispatch the action using cached state")
    next.completion?([enabled[0], ["isSelected": false, "isEnabled": false]], nil)

    try await waitUntil { !group.subitems[1].isEnabled }
    XCTAssertTrue(group.isSelected(at: 0))
    XCTAssertTrue(webView.requests.isEmpty)
  }

  func testAppearanceOverridesAndRegisteredDefaults() async throws {
    let editor = try await makeEditor()
    let toolbar = makeToolbar(editor)
    toolbar.itemIdentifiers = []

    _ = try await editor.webView.evaluateJavaScript("""
      window.appearance = {};
      const common = { title: 'Play', icon: 'play.fill', initialPlacement: 'toolbar', state: () => window.appearance };
      [
        { ...common, id: 'test.appearance.button', type: 'button', action() {} },
        { ...common, id: 'test.appearance.menu', type: 'menu', children: [{ title: 'Run', action() {} }] }
      ].forEach(item => MarkEdit.addToolbarItem(item));
      window.updateAppearance = state => {
        window.appearance = state;
        MarkEdit.invalidateToolbarItem('test.appearance.button');
        MarkEdit.invalidateToolbarItem('test.appearance.menu');
      };
      true;
      """)

    try await waitUntil { toolbar.items.count == 2 && toolbar.items.allSatisfy(\.isEnabled) }
    let items = toolbar.items
    XCTAssertEqual(items.map(\.itemIdentifier), [
      ExtensionToolbarController.identifier(for: "test.appearance.button"),
      ExtensionToolbarController.identifier(for: "test.appearance.menu"),
    ])

    let defaultImage = try XCTUnwrap(editor.createMenuIcon("play.fill")?.tiffRepresentation)
    let overrideImage = try XCTUnwrap(editor.createMenuIcon("pause.fill")?.tiffRepresentation)

    _ = try await editor.webView.evaluateJavaScript("window.updateAppearance({ title: 'Pause', icon: 'pause.fill' }); true;")
    try await waitUntil { items.allSatisfy { $0.label == "Pause" } }

    for (index, item) in items.enumerated() {
      XCTAssertIdentical(toolbar.items[index], item)
      XCTAssertEqual(item.toolTip, "Pause")
      XCTAssertEqual(item.paletteLabel, "Pause")

      let representation = item.menuFormRepresentation
      XCTAssertEqual(representation?.title, "Pause")
      XCTAssertEqual(representation?.attributedTitle?.string ?? representation?.title, "Pause")
      XCTAssertEqual(item.image?.tiffRepresentation, overrideImage)
      XCTAssertEqual(item.menuFormRepresentation?.image?.tiffRepresentation, overrideImage)

      let image = item.image
      let controller = try XCTUnwrap(item.extensionToolbarController)
      await controller.refreshState(forceFresh: true)
      XCTAssertIdentical(item.image, image)
    }

    _ = try await editor.webView.evaluateJavaScript("window.updateAppearance({ title: 'Resume' }); true;")
    try await waitUntil { items.allSatisfy { $0.label == "Resume" } }

    for item in items {
      XCTAssertEqual(item.image?.tiffRepresentation, defaultImage)
      XCTAssertEqual(item.menuFormRepresentation?.image?.tiffRepresentation, defaultImage)
    }

    _ = try await editor.webView.evaluateJavaScript("window.updateAppearance({}); true;")
    try await waitUntil { items.allSatisfy { $0.label == "Play" } }

    for item in items {
      XCTAssertEqual(item.toolTip, "Play")
      XCTAssertEqual(item.paletteLabel, "Play")
      let representation = item.menuFormRepresentation
      XCTAssertEqual(representation?.title, "Play")
      XCTAssertEqual(representation?.attributedTitle?.string ?? representation?.title, "Play")
    }
  }
}

private extension ExtensionToolbarTests {
  func makeEditor() async throws -> EditorViewController {
    let editor = EditorViewController()
    _ = editor.view

    try await waitUntil {
      editor.hasFinishedLoading
    }

    return editor
  }

  func makeSegmentedEditor() async throws -> EditorViewController {
    let editor = try await makeEditor()
    _ = try await editor.webView.evaluateJavaScript("""
      window.mode = 0;
      window.disabled = false;
      MarkEdit.addToolbarItem({
        id: 'test.mode', type: 'segmented', title: 'Modes', icon: 'eye',
        segments: [0, 1].map(index => ({
          title: ['Source', 'Preview'][index], icon: ['pencil', 'eye'][index],
          action() { window.mode = index; },
          state() { return { isSelected: window.mode === index, isEnabled: index === 0 || !window.disabled }; }
        }))
      });
      true;
      """)

    try await waitUntil {
      !editor.userDefinedToolbarItems.isEmpty
    }

    return editor
  }

  func makeToolbar(_ editor: EditorViewController, id: String = UUID().uuidString, autosaves: Bool = false) -> NSToolbar {
    let introduced = AppPreferences.Window.introducedToolbarItemIDs
    let cache = AppPreferences.Window.extensionToolbarCache
    let defaults = ExtensionToolbarController.cachedDefaults
    let window = NSPanel(
      contentRect: NSRect(x: 20, y: 20, width: 900, height: 400),
      styleMask: [.titled, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )

    let toolbar = NSToolbar(identifier: id)
    toolbar.displayMode = .iconOnly
    toolbar.delegate = editor
    toolbar.autosavesConfiguration = autosaves
    window.toolbar = toolbar
    window.contentViewController = editor

    addTeardownBlock {
      await MainActor.run {
        window.close()
        AppPreferences.Window.introducedToolbarItemIDs = introduced
        AppPreferences.Window.extensionToolbarCache = cache
        ExtensionToolbarController.cachedDefaults = defaults
        UserDefaults.standard.removeObject(forKey: "NSToolbar Configuration \(id)")
      }
    }

    return toolbar
  }

  func segmentedSpec(titles: [String] = ["Source", "Preview"]) -> WebToolbarItem {
    WebToolbarItem(
      id: UUID().uuidString,
      type: .segmented,
      title: "Modes",
      icon: "eye",
      initialPlacement: .toolbar,
      actionID: nil,
      stateGetterID: nil,
      children: nil,
      segments: titles.map {
        WebToolbarSegment(title: $0, icon: "eye", actionID: $0, stateGetterID: $0)
      }
    )
  }

  final class ToolbarInsertionObserver: NSObject {
    var notification: Notification?

    @objc func capture(_ notification: Notification) {
      self.notification = notification
    }
  }

  final class DeferredWebView: WKWebView {
    struct Request {
      let script: String
      let completion: (@MainActor @Sendable (Any?, (any Error)?) -> Void)?
    }

    var requests = [Request]()

    override func evaluateJavaScript(
      _ javaScriptString: String,
      completionHandler: (@MainActor @Sendable (Any?, (any Error)?) -> Void)? = nil
    ) {
      requests.append(Request(script: javaScriptString, completion: completionHandler))
    }
  }

  func waitUntil(
    _ condition: () -> Bool,
    file: StaticString = #filePath,
    line: UInt = #line
  ) async throws {
    let deadline = ContinuousClock.now + .seconds(10)
    while !condition(), ContinuousClock.now < deadline {
      try await Task.sleep(for: .milliseconds(10))
    }

    XCTAssertTrue(condition(), file: file, line: line)
  }
}
