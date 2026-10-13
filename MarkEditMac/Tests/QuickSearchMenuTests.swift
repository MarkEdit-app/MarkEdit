//
//  QuickSearchMenuTests.swift
//
//  Created by cyan on 10/12/26.
//

import AppKit
import AppKitExtensions
import XCTest
@testable import QuickSearchCore
@testable import QuickSearchUI
@testable import MarkEdit

@MainActor
final class QuickSearchMenuTests: XCTestCase {
  func testQuickSearchMenuWiring() throws {
    let appDelegate = try XCTUnwrap(NSApp.delegate as? AppDelegate)
    let searchItem = try XCTUnwrap(appDelegate.mainFileMenu?.items.first {
      $0.action == #selector(AppDelegate.quickSearch(_:))
    })

    XCTAssertTrue(searchItem.target is AppDelegate)

    let recentMenu = try XCTUnwrap(appDelegate.openRecentMenu)
    XCTAssertTrue(recentMenu.isDescendantOf(menu: appDelegate.mainFileMenu))
  }

  func testWindowListEntriesAreExcludedWithoutHidingWindowCommands() throws {
    let windows = try XCTUnwrap(NSApp.windowsMenu)
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
      styleMask: [.titled, .resizable],
      backing: .buffered,
      defer: false
    )

    let zoom = NSMenuItem(title: "Localized Zoom", action: #selector(NSWindow.zoom(_:)), keyEquivalent: "")
    zoom.target = window
    windows.addItem(zoom)

    defer {
      NSApp.removeWindowsItem(window)
      windows.removeItem(zoom)
    }

    NSApp.addWindowsItem(window, title: "Check Notes.md", filename: false)
    XCTAssertTrue(windows.items.contains {
      $0.target === window && $0.action == #selector(NSWindow.makeKeyAndOrderFront(_:))
    })

    let actions = QuickSearchMenuActions(menu: windows, sourceWindow: nil).actions
    XCTAssertTrue(actions.contains { $0.title == zoom.title })
    XCTAssertFalse(actions.contains { $0.title == "Check Notes.md" })

    let url = URL(filePath: "/Notes/Check Notes.md")
    let results = try QuickSearchResult.search(
      "check notes",
      filter: .all,
      recentURLs: [url],
      bookmarkedURLs: [],
      snapshot: nil,
      menuActions: actions
    )

    XCTAssertEqual(results.map(\.id), ["file:\(url.absoluteString)"])
  }

  func testSelectAllRestoresWebEditorFocus() async throws {
    let source = NSPanel(
      contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
      styleMask: [.titled, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )

    let editor = EditorViewController()
    source.contentViewController = editor
    source.makeKeyAndOrderFront(nil)
    defer { source.orderOut(nil) }

    let deadline = ContinuousClock.now + .seconds(10)
    while !editor.hasFinishedLoading, ContinuousClock.now < deadline {
      try await Task.sleep(for: .milliseconds(10))
    }

    XCTAssertTrue(editor.hasFinishedLoading)

    let text = "# First\n\nText\n\n# Second\n\nMore text"
    _ = try await editor.bridge.core.resetEditor(text: text, selectionRange: nil, documentChanged: true)
    source.makeKeyAndOrderFront(nil)
    editor.startTextEditing()

    _ = try await editor.webView.evaluateJavaScript("window.editor.focus()")
    XCTAssertIdentical(source.firstResponder, editor.webView)
    XCTAssertIdentical(NSApp.target(forAction: #selector(NSText.selectAll(_:))) as? NSObject, editor.webView)

    let menu = NSMenu()
    menu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)))
    let actions = QuickSearchMenuActions(
      menu: menu,
      sourceWindow: source
    ) {
      try await AppDelegate.refocusSourceWindow(source)
    }

    let action = try XCTUnwrap(actions.actions.first)
    let palette = NSPanel(
      contentRect: NSRect(x: 0, y: 0, width: 300, height: 100),
      styleMask: [.titled, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )

    let field = NSTextField()
    field.stringValue = "Select All"
    palette.contentView = field
    palette.makeKeyAndOrderFront(nil)
    palette.makeFirstResponder(field)
    defer { palette.orderOut(nil) }

    // Let WebKit process the focus transfer before restoring the source window
    _ = try await editor.bridge.core.getEditorState()
    palette.orderOut(nil)

    let resolved = try await actions.resolve(action)
    let item = try XCTUnwrap(resolved)
    XCTAssertIdentical(source.firstResponder, editor.webView)
    XCTAssertIdentical(
      NSApp.target(forAction: try XCTUnwrap(item.action), to: item.target, from: item) as? NSObject,
      editor.webView
    )

    item.performAction()
    let selected = try await editor.webView.evaluateJavaScript(
      "window.editor.state.sliceDoc(window.editor.state.selection.main.from, window.editor.state.selection.main.to)"
    )

    XCTAssertEqual(selected as? String, text)
  }
}
