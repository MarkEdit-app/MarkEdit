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

    let source = QuickSearchMenuActions(
      menu: try XCTUnwrap(NSApp.mainMenu),
      sourceWindow: nil,
      openRecentMenu: recentMenu,
      suggestedActions: AppDelegate.quickSearchSuggestedActions
    )

    let orders = source.actions.compactMap(\.suggestedOrder).sorted()
    XCTAssertEqual(orders, NSPasteboard.general.hasText ? [0, 1, 2, 3, 4] : [0, 2, 3, 4])
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
}
