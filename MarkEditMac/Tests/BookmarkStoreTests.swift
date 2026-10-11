//
//  BookmarkStoreTests.swift
//
//  Created by cyan on 10/11/26.
//

import AppKit
import MarkEditKit
import XCTest
@testable import MarkEdit

@MainActor
final class BookmarkStoreTests: XCTestCase {
  func testLegacyBookmarksSupportFilesFoldersAndRevocationWithoutDeletingData() throws {
    let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: folder) }

    let file = folder.appending(path: "Notes.md")
    try "Keep this content".write(to: file, atomically: true, encoding: .utf8)

    var stored: Data? = try bookmarkData(for: folder)
    var reads = 0
    var writes = 0

    let store = BookmarkStore(
      read: {
        reads += 1
        return stored
      },
      write: {
        writes += 1
        stored = $0
      },
      reportError: { XCTFail("\($0)") }
    )

    XCTAssertEqual(
      store.load().map { $0.url?.standardizedFileURL },
      [folder.standardizedFileURL]
    )

    reads = 0
    try store.add([folder, file, file])
    XCTAssertEqual(reads, 2)
    XCTAssertEqual(writes, 1)
    XCTAssertEqual(store.load().count, 2)
    XCTAssertEqual(try PropertyListDecoder().decode([Data].self, from: XCTUnwrap(stored)).count, 2)

    let folderBookmark = try XCTUnwrap(store.load().first)
    try store.revoke(folderBookmark)
    XCTAssertEqual(store.load().map { $0.url?.standardizedFileURL }, [file.standardizedFileURL])

    store.revokeAll()
    XCTAssertNil(stored)
    XCTAssertTrue(store.load().isEmpty)
    XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "Keep this content")
    XCTAssertTrue(FileManager.default.fileExists(atPath: folder.path))
  }

  func testBatchFailureDoesNotSavePartialBookmarks() throws {
    let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: folder) }

    let initial = try bookmarkData(for: folder)
    var stored: Data? = initial
    let store = BookmarkStore(read: { stored }, write: { stored = $0 }, reportError: { XCTFail("\($0)") })
    let file = folder.appending(path: "Notes.md")
    try Data("Fixture".utf8).write(to: file)

    XCTAssertThrowsError(try store.add([file, folder.appending(path: "Missing.md")]))
    XCTAssertEqual(stored, initial)
  }

  func testMenuShowsCompactDistinctNamesAndKeepsUnavailableBookmarksRevocable() throws {
    _ = NSApplication.shared
    let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    let urls = ["Work/Notes", "Personal/Notes"].map { root.appending(path: $0) }
    for url in urls {
      try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    defer { try? FileManager.default.removeItem(at: root) }
    var stored: Data? = try PropertyListEncoder().encode(urls.map { try bookmarkData(for: $0) })
    var errors: [Error] = []
    let store = BookmarkStore(read: { stored }, write: { stored = $0 }, reportError: { errors.append($0) })
    let delegate = AppDelegate()
    delegate.bookmarkStore = store

    let menu = NSMenu(title: "Bookmarks")
    delegate.bookmarksMenu = menu
    delegate.menuNeedsUpdate(menu)

    XCTAssertEqual(menu.items.map(\.title), [
      "Notes \u{2014} Work", "Notes \u{2014} Personal", "", Localized.Bookmarks.addBookmarks, Localized.Bookmarks.revokeAll,
    ])

    XCTAssertTrue(menu.items[2].isSeparatorItem)
    XCTAssertEqual(menu.items[0].toolTip, store.load().first?.url?.path)
    XCTAssertEqual(menu.items[0].submenu?.items.map(\.title), [
      Localized.Bookmarks.revealInFinder, Localized.Bookmarks.revokeBookmark,
    ])

    menu.items[0].submenu?.performActionForItem(at: 1)
    XCTAssertEqual(store.load().count, 1)

    delegate.menuNeedsUpdate(menu)
    menu.performActionForItem(at: menu.items.count - 1)
    XCTAssertNil(stored)

    delegate.menuNeedsUpdate(menu)
    XCTAssertEqual(menu.items.map(\.title), [Localized.Bookmarks.addBookmarks, Localized.Bookmarks.revokeAll])
    XCTAssertEqual(menu.items.last?.isEnabled, false)
    XCTAssertTrue(errors.isEmpty)

    stored = Data("Unavailable bookmark".utf8)
    delegate.menuNeedsUpdate(menu)

    let unavailable = try XCTUnwrap(menu.items.first?.submenu)
    XCTAssertFalse(unavailable.items[0].isEnabled)
    XCTAssertTrue(unavailable.items[1].isEnabled)
    XCTAssertFalse(errors.isEmpty)
    unavailable.performActionForItem(at: 1)
    XCTAssertNil(stored)
  }

  func testDisplayTitlesHandleRootedAndRelativeParentPaths() {
    let urls = [URL(filePath: "/Shared/Notes"), URL(filePath: "/A/Shared/Notes")]
    XCTAssertEqual(urls[0].displayTitle(among: urls), "Notes \u{2014} /Shared")
    XCTAssertEqual(urls[1].displayTitle(among: urls), "Notes \u{2014} A/Shared")

    let rootFile = URL(filePath: "/Notes")
    XCTAssertEqual(rootFile.displayTitle(among: [rootFile, urls[0]]), "Notes \u{2014} /")
  }

  func testLongNamesAreBoundedAndDuplicateGrantsAreRevokedTogether() throws {
    let name = String(repeating: "Long name ", count: 12) + ".md"
    let url = URL(filePath: "/Notes/\(name)")
    let title = url.displayTitle(among: [url])
    XCTAssertLessThanOrEqual(title.count, 60)
    XCTAssertTrue(title.contains("\u{2026}"))
    XCTAssertTrue(title.hasSuffix(".md"))

    let file = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try Data("Fixture".utf8).write(to: file)
    defer { try? FileManager.default.removeItem(at: file) }

    let data = try bookmarkData(for: file)
    var stored: Data? = try PropertyListEncoder().encode([data, data])
    let store = BookmarkStore(read: { stored }, write: { stored = $0 }, reportError: { XCTFail("\($0)") })
    try store.revoke(XCTUnwrap(store.load().first))
    XCTAssertNil(stored)
    XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))
  }

  private func bookmarkData(for url: URL) throws -> Data {
    try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
  }
}
