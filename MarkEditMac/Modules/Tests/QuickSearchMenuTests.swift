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

@MainActor
final class QuickSearchMenuTests: XCTestCase {
  func testRecursiveDiscoveryIncludesDisabledActionsAndChecksLiveState() async throws {
    let menu = NSMenu()
    let edit = submenu("Edit", in: menu)
    edit.addItem(withTitle: "New Tab") {}

    let nested = submenu("Nested", in: edit)
    let delegate = DynamicMenu()
    nested.delegate = delegate
    edit.addItem(.separator())
    edit.addItem(withTitle: "Hidden") {}.isHidden = true

    let disabledLeaf = edit.addItem(withTitle: "Disabled") {}
    disabledLeaf.isEnabled = false
    edit.addItem(withTitle: "Alternate") {}.isAlternate = true
    edit.addItem(withTitle: "No Action")
    edit.addItem(withTitle: "Missing Target", action: NSSelectorFromString("quickSearchMissingAction:"))
    edit.autoenablesItems = false

    let disabled = submenu("Disabled Parent", in: edit)
    disabled.addItem(withTitle: "Unreachable") {}
    disabled.superMenuItem?.isEnabled = false

    let recents = submenu("Localized Open Recent", in: menu)
    recents.addItem(withTitle: "New Tab.md") {}
    recents.addItem(.separator())

    let recentTarget = RecentMenuTarget()
    let clear = recents.addItem(withTitle: "Localized Clear Menu", action: #selector(NSDocumentController.clearRecentDocuments(_:)))
    clear.target = recentTarget

    let source = QuickSearchMenuActions(menu: menu, sourceWindow: nil, openRecentMenu: recents)
    XCTAssertEqual(source.actions.map(\.subtitle), [
      "Edit \u{203A} New Tab",
      "Edit \u{203A} Nested \u{203A} New Tab",
      "Edit \u{203A} Disabled",
      "Edit \u{203A} Missing Target",
      "Edit \u{203A} Disabled Parent \u{203A} Unreachable",
      "Localized Open Recent \u{203A} Localized Clear Menu",
    ])

    XCTAssertEqual(Set(source.actions.map(\.id)).count, 6)

    for title in ["Disabled", "Missing Target", "Unreachable"] {
      let action = try XCTUnwrap(source.actions.first { $0.title == title })
      let resolved = try await source.resolve(action)
      XCTAssertNil(resolved)
    }

    disabledLeaf.isEnabled = true
    let enabledAction = try XCTUnwrap(source.actions.first { $0.title == "Disabled" })
    let enabledItem = try await source.resolve(enabledAction)
    XCTAssertIdentical(enabledItem, disabledLeaf)

    for query in ["", "open recent", "clear menu"] {
      let matches = try MenuActionSearchResult.search(query, actions: source.actions)
      XCTAssertFalse(matches.contains { $0.action.title == "New Tab.md" })
      XCTAssertTrue(matches.contains { $0.action.title == clear.title })
    }

    let clearAction = try XCTUnwrap(source.actions.last)
    let clearItem = try await source.resolve(clearAction)
    try XCTUnwrap(clearItem).performAction()
    XCTAssertEqual(recentTarget.executions, 1)

    let action = source.actions[1]
    let oldItem = try XCTUnwrap(nested.items.first)
    let resolved = try await source.resolve(action)
    let item = try XCTUnwrap(resolved)
    XCTAssertIdentical(item, oldItem)
    item.performAction()
    XCTAssertEqual(delegate.executions, 1)

    item.isEnabled = false
    let disabledItem = try await source.resolve(action)
    XCTAssertNil(disabledItem)

    delegate.menuNeedsUpdate(nested)
    let rebuiltItem = try await source.resolve(action)
    XCTAssertIdentical(rebuiltItem, nested.items.first)
    XCTAssertNotIdentical(try XCTUnwrap(rebuiltItem), oldItem)

    menu.removeAllItems()
    let removedItem = try await source.resolve(try XCTUnwrap(source.actions.first))
    XCTAssertNil(removedItem)
  }

  func testMenuMatchingFiltersAndRanking() throws {
    let actions = [
      MenuActionSearchResult.Action(indices: [0, 0], titles: ["Edit", "New Tab"]),
      .init(indices: [1, 0], titles: ["Window", "New Tab"]),
      .init(indices: [1, 1], titles: ["Window", "New Tab Group"]),
    ]

    let file = URL(filePath: "/Notes/New Tab.md")
    let snapshot = QuickSearchDocumentSnapshot(
      text: "# New Tab\nNew Tab",
      headings: [.init(title: "New Tab", level: 1, lineNumber: 1)]
    )

    let fileID = "file:\(file.absoluteString)"
    let cases: [(String, QuickSearchFilter, [String])] = [
      ("new tab", .all, ["heading:1", "line:2", fileID, "menu:0.0", "menu:1.0", "menu:1.1"]),
      ("", .all, [fileID, "heading:1"]),
      ("", .menuActions, actions.map(\.id)),
      ("nwt", .menuActions, actions.map(\.id)),
      ("new tab", .recents, [fileID]),
      ("new tab", .bookmarks, []),
      ("new tab", .headings, ["heading:1"]),
      ("new tab", .contents, ["line:1", "line:2"]),
    ]

    for (query, filter, expected) in cases {
      let results = try QuickSearchResult.search(
        query,
        filter: filter,
        recentURLs: [file],
        bookmarkedURLs: [],
        snapshot: snapshot,
        menuActions: actions
      )

      XCTAssertEqual(results.map(\.id), expected, "\(query), \(filter)")
    }

    let match = try XCTUnwrap(MenuActionSearchResult.search("NEW TAB", actions: actions).first)
    XCTAssertEqual(match.match.ranges, [NSRange(location: 0, length: 7)])
  }

  func testMatchingMenuIncludesOnlyImmediateActions() throws {
    let actions = [
      MenuActionSearchResult.Action(indices: [0, 0, 0], titles: ["Format", "Headers", "Level 1"]),
      .init(indices: [0, 0, 1], titles: ["Format", "Headers", "Level 2"]),
      .init(indices: [0, 0, 2, 0], titles: ["Format", "Headers", "Advanced", "Nested Only"]),
      .init(indices: [1, 0], titles: ["Help", "Headers"]),
    ]

    let results = try MenuActionSearchResult.search("headers", actions: actions)
    XCTAssertEqual(results.map(\.action.title), ["Headers", "Level 1", "Level 2"])
    XCTAssertEqual(results.map(\.isExactMatch), [true, false, false])
    XCTAssertEqual(results.map(\.highlightedRanges), [[NSRange(location: 0, length: 7)], [], []])
    XCTAssertEqual(
      try MenuActionSearchResult.search("hdrs", actions: actions).map(\.action.title),
      ["Headers", "Level 1", "Level 2"]
    )

    XCTAssertEqual(
      try MenuActionSearchResult.search("nested", actions: actions).map(\.action.title),
      ["Nested Only"]
    )

    XCTAssertTrue(try MenuActionSearchResult.search("format", actions: actions).isEmpty)
  }

  func testContiguousMenuMatchesBeatScatteredActionMatches() throws {
    let actions = [
      MenuActionSearchResult.Action(indices: [0, 0], titles: ["Edit", "Check Spelling While Typing"]),
      .init(indices: [1, 0], titles: ["Extensions", "Help..."]),
      .init(indices: [2, 0], titles: ["Help", "MarkEdit Help"]),
      .init(indices: [2, 1], titles: ["Help", "Issue Tracker"]),
      .init(indices: [2, 2], titles: ["Help", "Version History"]),
    ]

    let results = try MenuActionSearchResult.search("help", actions: actions)
    XCTAssertEqual(results.map(\.action.title), [
      "Help...", "MarkEdit Help", "Issue Tracker", "Version History", "Check Spelling While Typing",
    ])

    XCTAssertEqual(results.map(\.isMenuMatch), [false, false, true, true, false])

    for menu in ["Help", "Helpful", "Get Help"] {
      let action = MenuActionSearchResult.Action(indices: [0, 0], titles: [menu, "Check Spelling"])
      let match = try XCTUnwrap(MenuActionSearchResult.search("help", actions: [action]).first)
      XCTAssertTrue(match.isMenuMatch)
      XCTAssertTrue(match.highlightedRanges.isEmpty)
      XCTAssertFalse(match.isExactMatch)
    }
  }

  func testTrailingEllipsesDoNotWeakenMenuTitleMatches() throws {
    for title in ["Help\u{2026}", "Help..."] {
      let action = MenuActionSearchResult.Action(indices: [0, 0], titles: ["Extensions", title])
      let match = try XCTUnwrap(MenuActionSearchResult.search("help", actions: [action]).first)
      XCTAssertTrue(match.isExactMatch)
      XCTAssertEqual(match.action.title, title)
      XCTAssertEqual(match.highlightedRanges, [NSRange(location: 0, length: 4)])
      XCTAssertEqual(try MenuActionSearchResult.search(title, actions: [action]).count, 1)
    }

    let actions = [
      MenuActionSearchResult.Action(indices: [0, 0], titles: ["Help\u{2026}", "Issue Tracker"]),
      .init(indices: [1, 0], titles: ["Extensions", "Help..."]),
      .init(indices: [1, 1], titles: ["Extensions", "Help... More"]),
    ]

    let results = try QuickSearchResult.search(
      "help",
      filter: .all,
      recentURLs: [],
      bookmarkedURLs: [],
      snapshot: .init(text: "help"),
      menuActions: actions
    )

    XCTAssertEqual(results.map(\.id), ["line:1", "menu:1.0", "menu:1.1", "menu:0.0"])

    let matches = try MenuActionSearchResult.search("help", actions: actions)
    XCTAssertEqual(matches.map(\.isExactMatch), [true, false, false])
    XCTAssertEqual(matches.last?.match.rank, 0)
    XCTAssertEqual(matches.last?.highlightedRanges, [])
  }
}

extension QuickSearchMenuTests {
  func testActivationRestoresSourceResponderAndRejectsDisabledAction() async throws {
    for enabled in [true, false] {
      // A nonactivating panel can become key even when the test app is in the background
      let source = NSPanel(
        contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
        styleMask: [.titled, .nonactivatingPanel],
        backing: .buffered,
        defer: false
      )

      let responder = MenuResponder()
      source.contentView = responder
      source.makeKeyAndOrderFront(nil)
      source.makeFirstResponder(responder)
      XCTAssertIdentical(NSApp.keyWindow, source)
      XCTAssertIdentical(source.firstResponder, responder)
      defer { source.orderOut(nil) }

      let menu = NSMenu()
      let edit = submenu("Edit", in: menu)
      edit.addItem(withTitle: "New Tab", action: #selector(MenuResponder.newTab(_:)))

      var errors: [String] = []
      var refocuses = 0
      let controller = QuickSearchController(
        effectViewType: NSVisualEffectView.self,
        placeholder: "Quick Search",
        accessibilityHelp: "Search",
        filterLabels: .init(
          title: "Filter Results",
          all: "All",
          recents: "Recents",
          bookmarks: "Bookmarks",
          headings: "Headings",
          contents: "Contents",
          menuActions: "Menu Actions",
          currentDocument: "Current Document"
        ),
        reportError: { errors.append($0) },
        openDocument: { _ in XCTFail("Menu action must not open a file") }
      )

      controller.present(
        recentURLs: [],
        menu: menu,
        refocusSourceWindow: {
          await Task.yield()
          source.makeKeyAndOrderFront(nil)
          refocuses += 1
        },
        screen: try XCTUnwrap(NSScreen.main)
      )

      let window = try XCTUnwrap(controller.window)
      defer { window.orderOut(nil) }

      let view = try XCTUnwrap(window.contentView as? QuickSearchView)
      let popup = try XCTUnwrap(view.subviews.compactMap { $0 as? NSPopUpButton }.first)
      let filters = try XCTUnwrap(popup.menu)
      filters.performActionForItem(at: try XCTUnwrap(filters.items.firstIndex { $0.title == "Menu Actions" }))

      let table: NSTableView = try XCTUnwrap(view.firstDescendant())
      XCTAssertEqual(table.numberOfRows, 1)
      let cell = try XCTUnwrap(table.view(atColumn: 0, row: 0, makeIfNecessary: true))
      XCTAssertEqual(cell.subviews.compactMap { $0 as? NSTextField }.map(\.stringValue), ["New Tab", "Edit \u{203A} New Tab"])
      XCTAssertNotNil(NSImage(systemSymbolName: "command", accessibilityDescription: nil))

      edit.items[0].isEnabled = enabled
      XCTAssertTrue(view.control(NSControl(), textView: NSTextView(), doCommandBy: #selector(NSResponder.insertNewline(_:))))

      let deadline = ContinuousClock.now + .seconds(3)
      while window.isActivatingResult, ContinuousClock.now < deadline {
        try await Task.sleep(for: .milliseconds(10))
      }

      XCTAssertFalse(window.isActivatingResult)
      XCTAssertEqual(refocuses, 1)
      XCTAssertFalse(window.isVisible)
      XCTAssertIdentical(NSApp.keyWindow, source)
      XCTAssertIdentical(source.firstResponder, responder)
      XCTAssertEqual(responder.executions, enabled ? 1 : 0)
      XCTAssertEqual(errors.count, enabled ? 0 : 1)
    }
  }

  private func submenu(_ title: String, in parent: NSMenu) -> NSMenu {
    let menu = NSMenu(title: title)
    parent.addItem(withTitle: title).submenu = menu
    return menu
  }
}

extension QuickSearchMenuTests {
  func testRefocusRevalidatesSourceAfterSuspension() async throws {
    let source = NSPanel(
      contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
      styleMask: [.titled, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )

    source.makeKeyAndOrderFront(nil)
    defer { source.orderOut(nil) }

    let menu = NSMenu()
    menu.addItem(withTitle: "Action") { XCTFail("Must not activate a stale source") }

    var refocuses = 0
    let actions = QuickSearchMenuActions(
      menu: menu,
      sourceWindow: source
    ) {
      await Task.yield()
      refocuses += 1
      source.orderOut(nil)
    }

    let action = try XCTUnwrap(actions.actions.first)
    let resolved = try await actions.resolve(action)
    XCTAssertNil(resolved)
    XCTAssertEqual(refocuses, 1)

    let hidden = try await actions.resolve(action)
    XCTAssertNil(hidden)
    XCTAssertEqual(refocuses, 1)
  }
}

@MainActor
private final class DynamicMenu: NSObject, NSMenuDelegate {
  var executions = 0

  func menuNeedsUpdate(_ menu: NSMenu) {
    menu.autoenablesItems = false
    menu.removeAllItems()
    menu.addItem(withTitle: "New Tab") { [weak self] in
      self?.executions += 1
    }
  }
}

@MainActor
private final class RecentMenuTarget: NSObject {
  var executions = 0

  @objc func clearRecentDocuments(_ sender: Any?) {
    executions += 1
  }
}

@MainActor
private final class MenuResponder: NSView, NSMenuItemValidation {
  var executions = 0

  override var acceptsFirstResponder: Bool {
    true
  }

  func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    true
  }

  @objc func newTab(_ sender: NSMenuItem) {
    XCTAssertIdentical(window, NSApp.keyWindow)
    XCTAssertIdentical(window?.firstResponder, self)
    executions += 1
  }
}
