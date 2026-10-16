//
//  QuickSearchFilterTests.swift
//
//  Created by cyan on 10/11/26.
//

import AppKit
import XCTest
@testable import QuickSearchCore
@testable import QuickSearchUI

@MainActor
final class QuickSearchFilterTests: XCTestCase {
  func testPopupFiltersWithoutChangingQueryAndRemembersSelection() async throws {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let bookmarked = directory.appending(path: "Bookmark Plan.md")
    try "Saved".write(to: bookmarked, atomically: true, encoding: .utf8)

    let document = QuickSearchDocument(
      title: "Untitled",
      url: nil,
      readSnapshot: {
        .init(text: "# Plan\n\nA plan", headings: [.init(title: "Plan", level: 1, lineNumber: 1)])
      },
      gotoLine: { _ in XCTFail("Filtering must not navigate") }
    )

    var helpRequests = 0
    let controller = QuickSearchController(
      effectViewType: NSVisualEffectView.self,
      placeholder: "Quick Search for files, text, and commands",
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
      filterMenuHelp: ("Help…", { helpRequests += 1 }),
      reportError: { XCTFail($0) },
      openDocument: { _ in XCTFail("Filtering must not open a document") }
    )

    let screen = try XCTUnwrap(NSScreen.main)
    let recents = [bookmarked, URL(filePath: "/Notes/Recent Plan.md")]
    controller.present(
      recentURLs: recents,
      locations: .init(urls: [directory], filenameExtensions: ["md"], showsHiddenFiles: false),
      document: document,
      screen: screen
    )

    defer {
      controller.window?.orderOut(nil)
    }

    let view = try XCTUnwrap(controller.window?.contentView as? QuickSearchView)
    let field = try XCTUnwrap(view.subviews.compactMap { $0 as? NSTextField }.first)
    let button = try XCTUnwrap(view.subviews.compactMap { $0 as? NSPopUpButton }.first)
    let menu = try XCTUnwrap(button.menu)
    let table: NSTableView = try XCTUnwrap(view.firstDescendant())
    let visibleItems = menu.items.filter { !$0.isHidden }

    XCTAssertEqual(
      visibleItems.map(\.title),
      [
        "All", "", "Recents", "Bookmarks", "Menu Actions", "", "Current Document", "Headings", "Contents",
        "", "Help…",
      ]
    )

    XCTAssertTrue(visibleItems[1].isSeparatorItem)
    XCTAssertTrue(visibleItems[5].isSeparatorItem)
    XCTAssertTrue(visibleItems[6].isSectionHeader)
    XCTAssertTrue(visibleItems[9].isSeparatorItem)

    menu.performActionForItem(at: try XCTUnwrap(menu.items.firstIndex { $0.title == "Help…" }))
    XCTAssertEqual(helpRequests, 1)

    XCTAssertEqual(visibleItems.last?.state, .off)
    XCTAssertEqual(menu.items.first { $0.title == "All" }?.state, .on)
    XCTAssertEqual(button.contentTintColor, .secondaryLabelColor)
    XCTAssertEqual(field.placeholderString, "Quick Search for files, text, and commands")

    view.layoutSubtreeIfNeeded()
    let placeholder = try XCTUnwrap(field.placeholderString)
    let font = try XCTUnwrap(field.font)
    let placeholderWidth = (placeholder as NSString).size(withAttributes: [.font: font]).width
    XCTAssertLessThanOrEqual(placeholderWidth, try XCTUnwrap(field.cell).drawingRect(forBounds: field.bounds).width)

    let icon = try XCTUnwrap(view.subviews.compactMap { $0 as? NSImageView }.first)
    XCTAssertEqual(button.frame.midY, icon.frame.midY, accuracy: 1)
    XCTAssertEqual(view.bounds.maxX - button.frame.maxX, icon.frame.minX, accuracy: 1)

    let iconRect = icon.alignmentRect(forFrame: icon.frame)
    let buttonRect = button.alignmentRect(forFrame: button.frame)
    let fieldRect = field.alignmentRect(forFrame: field.frame)
    XCTAssertEqual(iconRect.minX, 12, accuracy: 0.1)
    XCTAssertEqual(view.bounds.maxX - buttonRect.maxX, 12, accuracy: 0.1)
    XCTAssertEqual(fieldRect.minX - iconRect.maxX, 8, accuracy: 0.1)
    XCTAssertEqual(buttonRect.minX - fieldRect.maxX, 8, accuracy: 0.1)

    func select(_ title: String) throws {
      let index = try XCTUnwrap(menu.items.firstIndex { $0.title == title })
      menu.performActionForItem(at: index)
      XCTAssertEqual(menu.items[index].state, .on)
      XCTAssertEqual(button.contentTintColor, title == "All" ? .secondaryLabelColor : .controlAccentColor)
    }

    func waitForTitles(_ expected: [String]) async throws {
      let deadline = ContinuousClock.now.advanced(by: .seconds(3))

      func matches() -> Bool {
        guard table.numberOfRows == expected.count else {
          return false
        }

        return (0..<table.numberOfRows).compactMap {
          table.view(atColumn: 0, row: $0, makeIfNecessary: true)?
            .subviews.compactMap { $0 as? NSTextField }.first?.stringValue
        } == expected
      }

      while !matches(), ContinuousClock.now < deadline {
        try await Task.sleep(for: .milliseconds(10))
      }

      XCTAssertTrue(matches(), "Expected \(expected)")
    }

    func assertIcon(_ name: String) throws {
      let cell = try XCTUnwrap(table.view(atColumn: 0, row: 0, makeIfNecessary: true))
      let image = try XCTUnwrap(cell.subviews.compactMap { $0 as? NSImageView }.first?.image)
      let expected = NSImage.with(symbolName: name, pointSize: 18)
      XCTAssertEqual(try XCTUnwrap(image.tiffRepresentation), try XCTUnwrap(expected.tiffRepresentation))
    }

    try assertIcon("clock")
    try select("Bookmarks")
    try await waitForTitles(["Bookmark Plan.md"])
    try assertIcon("bookmark")

    try select("Recents")
    try await waitForTitles(["Bookmark Plan.md", "Recent Plan.md"])
    try assertIcon("clock")

    try select("Contents")
    try await waitForTitles([])

    field.stringValue = "plan"
    view.controlTextDidChange(Notification(name: NSControl.textDidChangeNotification, object: field))
    try await waitForTitles(["# Plan", "A plan"])

    try select("Recents")
    try select("Bookmarks")
    try await waitForTitles(["Bookmark Plan.md"])

    try select("Headings")
    try await waitForTitles(["Plan"])
    XCTAssertEqual(field.stringValue, "plan")
    XCTAssertNotNil(field.currentEditor())

    try select("All")
    try select("Headings")
    controller.window?.cancelOperation(nil)
    controller.present(recentURLs: recents, document: document, screen: screen)

    let reopened = try XCTUnwrap(controller.window?.contentView as? QuickSearchView)
    let reopenedButton = try XCTUnwrap(reopened.subviews.compactMap { $0 as? NSPopUpButton }.first)
    XCTAssertEqual(reopenedButton.menu?.items.first { $0.title == "Headings" }?.state, .on)
    XCTAssertEqual(reopenedButton.contentTintColor, .controlAccentColor)

    menu.performActionForItem(at: try XCTUnwrap(menu.items.firstIndex { $0.title == "All" }))
    XCTAssertEqual(reopenedButton.menu?.items.first { $0.title == "Headings" }?.state, .on)
    XCTAssertEqual(reopenedButton.contentTintColor, .controlAccentColor)
  }
}
