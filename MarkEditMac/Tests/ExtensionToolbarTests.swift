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
    let originalPromoted = AppPreferences.Window.promotedToolbarItemIDs
    let toolbarID = NSToolbar.Identifier(UUID().uuidString)
    defer {
      AppPreferences.Window.promotedToolbarItemIDs = originalPromoted
      UserDefaults.standard.removeObject(forKey: "NSToolbar Configuration \(toolbarID)")
    }

    let titles = ["Markdown Source", "Preview (Side-by-Side)", "Preview (Overlay)", "Mixed (Syntax Hidden)"]
    let spec = WebToolbarItem(id: UUID().uuidString, title: "View Mode", icon: "eye", segments: titles.map {
      WebToolbarSegment(title: $0, icon: "eye", actionID: $0, stateGetterID: $0)
    })

    let itemID = ExtensionToolbarController.identifier(for: spec.id)
    let editor = EditorViewController(preloadDelay: 60)
    let window = NSPanel(
      contentRect: NSRect(x: 20, y: 20, width: 900, height: 400),
      styleMask: [.titled, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )

    window.contentViewController = editor
    defer { window.close() }

    let toolbar = NSToolbar(identifier: toolbarID)
    toolbar.displayMode = .iconOnly
    toolbar.delegate = editor
    toolbar.autosavesConfiguration = true
    window.toolbar = toolbar

    let originalItems: [NSToolbarItem.Identifier] = [.formatHeaders, .toggleBold, .toggleItalic, .toggleList]
    toolbar.itemIdentifiers = originalItems

    editor.addToolbarItems([spec])
    window.orderFront(nil)

    let group = try XCTUnwrap(toolbar.items.last as? NSToolbarItemGroup)
    group.controlRepresentation = .expanded
    window.contentView?.superview?.layoutSubtreeIfNeeded()
    XCTAssertEqual(toolbar.visibleItems?.map(\.itemIdentifier), originalItems + [itemID])
    XCTAssertTrue(AppPreferences.Window.promotedToolbarItemIDs.contains(spec.id))

    toolbar.removeItem(at: toolbar.items.count - 1)
    editor.configureToolbar()
    XCTAssertEqual(toolbar.itemIdentifiers, originalItems)

    let reopened = EditorViewController(preloadDelay: 60)
    reopened.addToolbarItems([spec])

    let reopenedWindow = NSPanel(contentViewController: reopened)
    defer { reopenedWindow.close() }

    let restored = NSToolbar(identifier: toolbarID)
    restored.delegate = reopened
    restored.autosavesConfiguration = true
    reopenedWindow.toolbar = restored
    reopened.configureToolbar()
    XCTAssertEqual(restored.itemIdentifiers, originalItems)
    XCTAssertTrue(reopened.toolbarAllowedItemIdentifiers(restored).contains(itemID))
  }

  func testCopiedOverflowMenuKeepsIconStateAndActions() async throws {
    let editor = EditorViewController()
    _ = editor.view

    try await waitUntil { editor.hasFinishedLoading }
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

    try await waitUntil { !editor.userDefinedToolbarItems.isEmpty }
    let spec = try XCTUnwrap(editor.userDefinedToolbarItems.first)
    let group = try XCTUnwrap(ExtensionToolbarController.makeToolbarItem(spec: spec, editor: editor))

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

  func testPlaceholderResolutionPreservesOtherWindowItems() throws {
    let originalPromoted = AppPreferences.Window.promotedToolbarItemIDs
    defer { AppPreferences.Window.promotedToolbarItemIDs = originalPromoted }
    let spec = WebToolbarItem(
      id: UUID().uuidString,
      title: "Modes",
      icon: "eye",
      segments: ["Source", "Preview"].map {
        WebToolbarSegment(title: $0, icon: "eye", actionID: $0, stateGetterID: $0)
      }
    )

    let first = EditorViewController(preloadDelay: 60)
    let second = EditorViewController(preloadDelay: 60)
    let firstWindow = NSPanel(contentViewController: first)
    let secondWindow = NSPanel(contentViewController: second)
    defer {
      firstWindow.close()
      secondWindow.close()
    }

    let toolbarID = UUID().uuidString
    let firstToolbar = NSToolbar(identifier: toolbarID)
    firstToolbar.delegate = first
    firstWindow.toolbar = firstToolbar
    firstToolbar.itemIdentifiers = []
    first.addToolbarItems([spec])

    let original = try XCTUnwrap(firstToolbar.items.first as? NSToolbarItemGroup)
    let originalController = try XCTUnwrap(original.extensionToolbarController)
    original.setSelected(true, at: 1)
    original.subitems.forEach { $0.isEnabled = true }

    let secondToolbar = NSToolbar(identifier: toolbarID)
    secondToolbar.delegate = second
    secondWindow.toolbar = secondToolbar

    let placeholder = try XCTUnwrap(secondToolbar.items.first as? NSToolbarItemGroup)
    XCTAssertTrue(placeholder.subitems.isEmpty)
    XCTAssertFalse(placeholder.isEnabled)

    second.addToolbarItems([spec])
    XCTAssertIdentical(secondToolbar.items.first, placeholder)
    XCTAssertEqual(placeholder.subitems.count, 2)
    XCTAssertTrue(placeholder.subitems.allSatisfy { !$0.isEnabled })
    XCTAssertIdentical(firstToolbar.items.first, original)
    XCTAssertIdentical(original.extensionToolbarController, originalController)
    XCTAssertTrue(original.isSelected(at: 1))
    XCTAssertTrue(original.subitems.allSatisfy(\.isEnabled))
  }

  func testInsertionNotificationContainsActualGroupAndBindsActions() async throws {
    let editor = EditorViewController()
    _ = editor.view

    try await waitUntil {
      editor.hasFinishedLoading
    }

    _ = try await editor.webView.evaluateJavaScript("""
      window.mode = 0;
      MarkEdit.addToolbarItem({
        id: 'test.palette', type: 'segmented', title: 'Modes', icon: 'eye',
        segments: [0, 1].map(index => ({
          title: String(index), icon: 'eye',
          action() { window.mode = index; },
          state() { return { isSelected: window.mode === index }; }
        }))
      });
      true;
      """)

    try await waitUntil { !editor.userDefinedToolbarItems.isEmpty }
    let window = NSPanel(contentViewController: editor)
    defer { window.close() }

    let toolbar = NSToolbar(identifier: UUID().uuidString)
    toolbar.delegate = editor
    window.toolbar = toolbar
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

    toolbar.insertItem(withItemIdentifier: ExtensionToolbarController.identifier(for: "test.palette"), at: 0)
    let notification = try XCTUnwrap(observer.notification)
    XCTAssertIdentical(notification.object as? NSToolbar, toolbar)

    let group = try XCTUnwrap(notification.userInfo?[NSToolbarUserInfoKey.itemKey.rawValue] as? NSToolbarItemGroup)
    XCTAssertIdentical(group, toolbar.items.first)
    XCTAssertNotNil(group.extensionToolbarController)

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

    let spec = WebToolbarItem(
      id: UUID().uuidString,
      title: "Modes",
      icon: "eye",
      segments: ["Source", "Preview"].map {
        WebToolbarSegment(title: $0, icon: "eye", actionID: $0, stateGetterID: $0)
      }
    )

    let group = try XCTUnwrap(ExtensionToolbarController.makeToolbarItem(spec: spec, editor: editor))
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

  private final class ToolbarInsertionObserver: NSObject {
    var notification: Notification?

    @objc func capture(_ notification: Notification) {
      self.notification = notification
    }
  }

  private final class DeferredWebView: WKWebView {
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

  private func waitUntil(
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
