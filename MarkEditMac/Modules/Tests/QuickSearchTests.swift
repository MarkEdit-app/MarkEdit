//
//  QuickSearchTests.swift
//
//  Created by cyan on 10/11/26.
//

import AppKit
import XCTest
@testable import QuickSearchCore
@testable import QuickSearchUI

@MainActor
final class QuickSearchTests: XCTestCase {
  func testOpenPanelShortcutRegistrationIsScopedAndReleased() {
    var registrations = 0
    var cancellations = 0
    let shortcut = OpenPanelShortcut(panel: NSOpenPanel()) { _ in
      registrations += 1
      return { cancellations += 1 }
    }

    XCTAssertEqual(registrations, 0)

    shortcut.setEnabled(true)
    shortcut.setEnabled(true)
    XCTAssertEqual(registrations, 1)

    shortcut.setEnabled(false)
    XCTAssertEqual(cancellations, 1)

    shortcut.setEnabled(true)
    XCTAssertEqual(registrations, 2)

    shortcut.stop()
    shortcut.stop()
    shortcut.setEnabled(true)
    XCTAssertEqual(registrations, 2)
    XCTAssertEqual(cancellations, 2)
  }

  func testOpenPanelShortcutObserversSuspendAndStop() {
    let panel = NSOpenPanel()
    let unrelatedWindow = NSWindow()
    var registrations = 0
    var cancellations = 0
    let shortcut = OpenPanelShortcut(panel: panel) { _ in
      registrations += 1
      return { cancellations += 1 }
    }

    defer { shortcut.stop() }
    let center = NotificationCenter.default
    let suspensions: [(Notification.Name, AnyObject)] = [
      (NSApplication.willResignActiveNotification, NSApplication.shared),
      (NSWindow.willBeginSheetNotification, panel),
      (NSWindow.willCloseNotification, panel),
    ]

    for (name, object) in suspensions {
      shortcut.setEnabled(true)
      let previousCancellations = cancellations

      center.post(name: name, object: unrelatedWindow)
      XCTAssertEqual(cancellations, previousCancellations)

      center.post(name: name, object: object)
      XCTAssertEqual(cancellations, previousCancellations + 1)
      center.post(name: name, object: object)
      XCTAssertEqual(cancellations, previousCancellations + 1)
    }

    // A hidden panel must revoke registration when its active state is reevaluated
    let changes: [(Notification.Name, AnyObject)] = [
      (NSApplication.didBecomeActiveNotification, NSApplication.shared),
      (NSWindow.didBecomeKeyNotification, unrelatedWindow),
      (NSWindow.didResignKeyNotification, unrelatedWindow),
      (NSWindow.didEndSheetNotification, panel),
    ]

    for (name, object) in changes {
      shortcut.setEnabled(true)
      let previousCancellations = cancellations
      center.post(name: name, object: object)
      XCTAssertEqual(cancellations, previousCancellations + 1)
    }

    shortcut.stop()
    let previousRegistrations = registrations
    center.post(name: NSApplication.didBecomeActiveNotification, object: NSApplication.shared)
    center.post(name: NSWindow.didBecomeKeyNotification, object: panel)
    center.post(name: NSWindow.didEndSheetNotification, object: panel)
    XCTAssertEqual(registrations, previousRegistrations)
  }

  func testActivationWaitsForResultsMatchingTheCurrentQueryAndFilter() async throws {
    var opened: [URL] = []
    var activations = 0
    let controller = QuickSearchController(
      effectViewType: NSVisualEffectView.self,
      placeholder: { _ in "Quick Search" },
      accessibilityHelp: "Search",
      filterLabels: filterLabels,
      reportError: { XCTFail($0) },
      onResultActivated: { activations += 1 },
      openDocument: { opened.append($0) }
    )

    let urls = ["First.md", "Second.md"].map { URL(filePath: "/Notes/\($0)") }
    controller.present(recentURLs: urls, screen: try XCTUnwrap(NSScreen.main))
    let window = try XCTUnwrap(controller.window)
    defer { window.orderOut(nil) }

    let view = try XCTUnwrap(window.contentView as? QuickSearchView)
    let field = try XCTUnwrap(view.subviews.compactMap { $0 as? NSTextField }.first)
    let button = try XCTUnwrap(view.subviews.compactMap { $0 as? NSPopUpButton }.first)
    let menu = try XCTUnwrap(button.menu)
    let table: NSTableView = try XCTUnwrap(view.firstDescendant())
    let submit = #selector(NSResponder.insertNewline(_:))
    XCTAssertEqual(table.numberOfRows, 2)

    field.stringValue = "Second"
    view.controlTextDidChange(Notification(name: NSControl.textDidChangeNotification, object: field))
    XCTAssertTrue(view.control(field, textView: NSTextView(), doCommandBy: submit))
    XCTAssertFalse(window.isActivatingResult)
    XCTAssertTrue(window.isVisible)
    try await waitUntil { table.numberOfRows == 1 }
    XCTAssertTrue(opened.isEmpty)
    XCTAssertEqual(activations, 0)

    let bookmarks = try XCTUnwrap(menu.items.firstIndex { $0.title == "Bookmarks" })
    menu.performActionForItem(at: bookmarks)
    XCTAssertEqual(menu.items[bookmarks].state, .on)
    XCTAssertTrue(view.control(field, textView: NSTextView(), doCommandBy: submit))
    XCTAssertFalse(window.isActivatingResult)
    XCTAssertTrue(window.isVisible)
    try await waitUntil { table.numberOfRows == 0 }
    XCTAssertTrue(opened.isEmpty)

    let recents = try XCTUnwrap(menu.items.firstIndex { $0.title == "Recents" })
    menu.performActionForItem(at: recents)
    try await waitUntil { table.numberOfRows == 1 }
    XCTAssertTrue(view.control(field, textView: NSTextView(), doCommandBy: submit))
    try await waitUntil { !window.isVisible }
    XCTAssertEqual(opened, [urls[1]])
    XCTAssertEqual(activations, 1)
  }
}

extension QuickSearchTests {
  func testSuccessfulActivationReleasesSessionAfterLosingFocus() async throws {
    final class Token { let text = "" }
    weak var retainedToken: Token?
    var palette: QuickSearchWindow?
    var activations = 0
    let controller = QuickSearchController(
      effectViewType: NSVisualEffectView.self,
      placeholder: { _ in "Quick Search" },
      accessibilityHelp: "Search",
      filterLabels: filterLabels,
      reportError: { XCTFail($0) },
      onResultActivated: { activations += 1 },
      openDocument: { _ in
        XCTAssertEqual(palette?.isActivatingResult, true)
        palette?.resignKey()
      }
    )

    do {
      let token = Token()
      retainedToken = token
      controller.present(
        recentURLs: [URL(filePath: "/Notes/Plan.md")],
        document: .init(
          title: "Source",
          url: nil,
          readSnapshot: { .init(text: token.text) },
          gotoLine: { _ in XCTFail("Expected file activation") }
        ),
        screen: try XCTUnwrap(NSScreen.main)
      )
    }

    let window = try XCTUnwrap(controller.window)
    palette = window
    defer { window.orderOut(nil) }
    XCTAssertNotNil(retainedToken)

    let view = try XCTUnwrap(window.contentView as? QuickSearchView)
    XCTAssertTrue(view.control(NSControl(), textView: NSTextView(), doCommandBy: #selector(NSResponder.insertNewline(_:))))
    try await waitUntil { !window.isActivatingResult }
    XCTAssertFalse(window.isVisible)
    XCTAssertEqual(activations, 1)
    withExtendedLifetime(controller) {
      XCTAssertNil(retainedToken)
    }
  }

  func testRecentFileActivationNotifiesOnlyOnSuccessWithoutAQuery() async throws {
    for shouldFail in [true, false] {
      var errors: [String] = []
      var activations = 0
      let controller = QuickSearchController(
        effectViewType: NSVisualEffectView.self,
        placeholder: { _ in "Quick Search" },
        accessibilityHelp: "Search",
        filterLabels: filterLabels,
        reportError: { errors.append($0) },
        onResultActivated: { activations += 1 },
        openDocument: { _ in
          if shouldFail {
            throw CocoaError(.fileNoSuchFile)
          }
        }
      )

      controller.present(recentURLs: [URL(filePath: "/Notes/Plan.md")], screen: try XCTUnwrap(NSScreen.main))
      let window = try XCTUnwrap(controller.window)
      defer { window.orderOut(nil) }
      XCTAssertEqual(activations, 0)

      let view = try XCTUnwrap(window.contentView as? QuickSearchView)
      XCTAssertTrue(view.control(NSControl(), textView: NSTextView(), doCommandBy: #selector(NSResponder.insertNewline(_:))))
      try await waitUntil { !window.isActivatingResult }
      XCTAssertEqual(errors.count, shouldFail ? 1 : 0)
      XCTAssertEqual(activations, shouldFail ? 0 : 1)
    }
  }
}

extension QuickSearchTests {
  func testLiveHeadingsUseFuzzySearchAndPrecedeContentWithoutDuplicates() async throws {
    var snapshot = QuickSearchDocumentSnapshot(
      text: "# Release Plan\n\n## Project Planning\n\nA plan for launch.",
      headings: [
        .init(title: "Release Plan", level: 1, lineNumber: 1),
        .init(title: "Project Planning", level: 2, lineNumber: 3),
      ]
    )

    var errors: [String] = []
    var navigatedLines: [Int] = []
    var activations = 0

    let document = QuickSearchDocument(
      title: "Untitled",
      url: nil,
      readSnapshot: { snapshot },
      gotoLine: { navigatedLines.append($0) }
    )

    let controller = QuickSearchController(
      effectViewType: NSVisualEffectView.self,
      placeholder: { _ in "Quick Search" },
      accessibilityHelp: "Search",
      filterLabels: filterLabels,
      reportError: { errors.append($0) },
      onResultActivated: { activations += 1 },
      openDocument: { _ in XCTFail("Expected heading navigation") }
    )

    let screen = try XCTUnwrap(NSScreen.main)
    let recentURLs = [URL(filePath: "/Notes/Plan.md")]
    controller.present(recentURLs: recentURLs, document: document, screen: screen)
    defer { controller.window?.orderOut(nil) }

    var view = try XCTUnwrap(controller.window?.contentView as? QuickSearchView)
    var field = try XCTUnwrap(view.subviews.compactMap { $0 as? NSTextField }.first)
    var table: NSTableView = try XCTUnwrap(view.firstDescendant())
    XCTAssertEqual(table.numberOfRows, 1)

    func search(_ query: String, count: Int) async throws {
      field.stringValue = query
      view.controlTextDidChange(Notification(name: NSControl.textDidChangeNotification, object: field))

      try await waitUntil {
        guard table.numberOfRows == count else {
          return false
        }

        guard query == "pp" else {
          return true
        }

        let cell = table.view(atColumn: 0, row: 0, makeIfNecessary: true)
        return cell?.subviews.compactMap { $0 as? NSTextField }.first?.stringValue == "Project Planning"
      }
    }

    try await search("", count: 3)
    let initialTitles = try (0..<3).map { row in
      let cell = try XCTUnwrap(table.view(atColumn: 0, row: row, makeIfNecessary: true))
      return try XCTUnwrap(cell.subviews.compactMap { $0 as? NSTextField }.first).stringValue
    }

    XCTAssertEqual(initialTitles, ["Plan.md", "Release Plan", "Project Planning"])
    try await search("#", count: 2)
    try await search("##", count: 1)
    try await search("plan", count: 4)

    let titles = try (0..<4).map { row in
      let cell = try XCTUnwrap(table.view(atColumn: 0, row: row, makeIfNecessary: true))
      return try XCTUnwrap(cell.subviews.compactMap { $0 as? NSTextField }.first).stringValue
    }

    XCTAssertEqual(titles, ["Release Plan", "Project Planning", "A plan for launch.", "Plan.md"])
    try await search("pp", count: 1)
    let submit = #selector(NSResponder.insertNewline(_:))
    snapshot = .init(
      text: "\n" + snapshot.text,
      headings: snapshot.headings.map {
        .init(title: $0.title, level: $0.level, lineNumber: $0.lineNumber + 1)
      }
    )

    XCTAssertTrue(view.control(field, textView: NSTextView(), doCommandBy: submit))
    try await waitUntil {
      let cell = table.view(atColumn: 0, row: 0, makeIfNecessary: true)
      return cell?.subviews.compactMap { $0 as? NSTextField }.last?.stringValue == "Untitled:4"
        && controller.window?.isActivatingResult == false
    }

    XCTAssertTrue(errors.isEmpty)
    XCTAssertEqual(controller.window?.isVisible, true)
    XCTAssertTrue(navigatedLines.isEmpty)
    XCTAssertEqual(activations, 0)

    controller.window?.cancelOperation(nil)
    controller.present(recentURLs: recentURLs, document: document, screen: screen)
    view = try XCTUnwrap(controller.window?.contentView as? QuickSearchView)
    field = try XCTUnwrap(view.subviews.compactMap { $0 as? NSTextField }.first)
    table = try XCTUnwrap(view.firstDescendant())

    try await search("", count: 3)
    XCTAssertTrue(view.control(field, textView: NSTextView(), doCommandBy: #selector(NSResponder.moveDown(_:))))
    XCTAssertTrue(view.control(field, textView: NSTextView(), doCommandBy: #selector(NSResponder.moveDown(_:))))
    XCTAssertTrue(view.control(field, textView: NSTextView(), doCommandBy: submit))
    try await waitUntil { navigatedLines == [4] }
    XCTAssertEqual(activations, 1)

    controller.present(recentURLs: recentURLs, screen: screen)
    let newView = try XCTUnwrap(controller.window?.contentView as? QuickSearchView)
    let newField = try XCTUnwrap(newView.subviews.compactMap { $0 as? NSTextField }.first)
    newField.stringValue = "pp"
    newView.controlTextDidChange(Notification(name: NSControl.textDidChangeNotification, object: newField))
    let newTable: NSTableView = try XCTUnwrap(newView.firstDescendant())
    try await waitUntil { newTable.numberOfRows == 0 }
  }

  func testCancelledActivationCannotDismissNextInvocation() async throws {
    let started = expectation(description: "Opening started")
    let finished = expectation(description: "Opening finished")
    var continuation: CheckedContinuation<Void, any Error>?
    var opens = 0
    var activations = 0

    let controller = QuickSearchController(
      effectViewType: NSVisualEffectView.self,
      placeholder: { _ in "Quick Search" },
      accessibilityHelp: "Search files",
      filterLabels: filterLabels,
      reportError: { XCTFail($0) },
      onResultActivated: { activations += 1 },
      openDocument: { _ in
        opens += 1
        defer { finished.fulfill() }

        try await withCheckedThrowingContinuation {
          continuation = $0
          started.fulfill()
        }
      }
    )

    let screen = try XCTUnwrap(NSScreen.main)
    let urls = [URL(filePath: "/Notes/Plan.md")]
    controller.present(recentURLs: urls, screen: screen)

    let firstWindow = try XCTUnwrap(controller.window)
    XCTAssertEqual(firstWindow.frame.midX, screen.visibleFrame.midX, accuracy: 1)
    XCTAssertEqual(firstWindow.frame.maxY, screen.visibleFrame.maxY - 200, accuracy: 1)
    defer { controller.window?.orderOut(nil) }

    let view = try XCTUnwrap(firstWindow.contentView as? QuickSearchView)
    let field = try XCTUnwrap(view.subviews.compactMap { $0 as? NSTextField }.first)
    let submit = #selector(NSResponder.insertNewline(_:))

    XCTAssertTrue(view.control(field, textView: NSTextView(), doCommandBy: submit))
    XCTAssertTrue(view.control(field, textView: NSTextView(), doCommandBy: submit))
    await fulfillment(of: [started], timeout: 2)
    XCTAssertEqual(opens, 1)

    firstWindow.cancelOperation(nil)
    controller.present(recentURLs: urls, screen: screen)
    let secondWindow = try XCTUnwrap(controller.window)
    XCTAssertNotIdentical(firstWindow, secondWindow)

    continuation?.resume(throwing: CocoaError(.fileNoSuchFile))
    await fulfillment(of: [finished], timeout: 2)
    await Task.yield()
    XCTAssertTrue(secondWindow.isVisible)
    XCTAssertFalse(secondWindow.isActivatingResult)
    XCTAssertEqual(activations, 0)
  }

  func testGrantedAndLiveContentResultsRejectStaleMatchesThenNavigate() async throws {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let file = directory.appending(path: "Plan.md")
    try "saved text".write(to: file, atomically: true, encoding: .utf8)

    var text = "Heading\r\n\r\nUnsaved \u{1F4C4} plan"
    var errors: [String] = []
    var navigatedLines: [Int] = []

    let document = QuickSearchDocument(
      title: "Untitled",
      url: nil,
      readSnapshot: { QuickSearchDocumentSnapshot(text: text) },
      gotoLine: { navigatedLines.append($0) }
    )

    let locations = QuickSearchLocations(urls: [directory], filenameExtensions: ["md"], showsHiddenFiles: false)
    let controller = QuickSearchController(
      effectViewType: NSVisualEffectView.self,
      placeholder: { _ in "Quick Search" },
      accessibilityHelp: "Search",
      filterLabels: filterLabels,
      reportError: { errors.append($0) },
      openDocument: { _ in XCTFail("Expected line navigation") }
    )

    let screen = try XCTUnwrap(NSScreen.main)
    controller.present(recentURLs: [], locations: locations, document: document, screen: screen)
    defer { controller.window?.orderOut(nil) }

    func searchAndSelectContent() async throws -> QuickSearchView {
      let view = try XCTUnwrap(controller.window?.contentView as? QuickSearchView)
      let field = try XCTUnwrap(view.subviews.compactMap { $0 as? NSTextField }.first)

      field.stringValue = "no match"
      view.controlTextDidChange(Notification(name: NSControl.textDidChangeNotification, object: field))
      field.stringValue = "plan"
      view.controlTextDidChange(Notification(name: NSControl.textDidChangeNotification, object: field))

      let results = try XCTUnwrap(view.subviews.first { $0 is QuickSearchResultsView })
      let scroll = try XCTUnwrap(results.subviews.compactMap { $0 as? NSScrollView }.first)
      let table = try XCTUnwrap(scroll.documentView as? NSTableView)
      try await waitUntil { table.numberOfRows == 2 }
      let message = try XCTUnwrap(results.subviews.compactMap { $0 as? NSTextField }.first)
      let frame = controller.window?.frame

      for query in ["p", "pla", "no match"] {
        field.stringValue = query
        view.controlTextDidChange(Notification(name: NSControl.textDidChangeNotification, object: field))
        XCTAssertEqual(table.numberOfRows, 2)
        XCTAssertEqual(controller.window?.frame, frame)
        XCTAssertTrue(message.isHidden)
      }

      try await waitUntil { table.numberOfRows == 0 && controller.window?.frame.height == 48 }
      XCTAssertTrue(results.isHidden)
      XCTAssertTrue(message.isHidden)
      XCTAssertEqual(controller.window?.frame.height, 48)
      XCTAssertEqual(controller.window?.frame.maxY, frame?.maxY)
      XCTAssertNotNil(field.currentEditor())

      field.stringValue = "plan"
      view.controlTextDidChange(Notification(name: NSControl.textDidChangeNotification, object: field))
      try await waitUntil { table.numberOfRows == 2 }
      XCTAssertFalse(results.isHidden)
      XCTAssertEqual(table.selectedRow, 0)

      return view
    }

    let firstView = try await searchAndSelectContent()
    text = "Heading\r\nInserted\r\n\r\nUnsaved \u{1F4C4} plan"
    let submit = #selector(NSResponder.insertNewline(_:))
    XCTAssertTrue(firstView.control(NSControl(), textView: NSTextView(), doCommandBy: submit))

    let table: NSTableView = try XCTUnwrap(firstView.firstDescendant())
    try await waitUntil {
      let cell = table.view(atColumn: 0, row: 0, makeIfNecessary: true)
      return cell?.subviews.compactMap { $0 as? NSTextField }.last?.stringValue == "Untitled:4"
        && controller.window?.isActivatingResult == false
    }

    XCTAssertTrue(errors.isEmpty)
    XCTAssertEqual(controller.window?.isVisible, true)
    XCTAssertTrue(navigatedLines.isEmpty)

    XCTAssertEqual(table.selectedRow, 0)
    XCTAssertTrue(firstView.control(NSControl(), textView: NSTextView(), doCommandBy: submit))
    try await waitUntil { !navigatedLines.isEmpty }
    XCTAssertEqual(navigatedLines, [4])
    XCTAssertFalse(try XCTUnwrap(controller.window).isVisible)
  }
}

extension QuickSearchTests {
  func testUnavailableDocumentRemovesItsResultsWithoutDismissingPalette() async throws {
    for stage in ["refresh", "activation", "navigation"] {
      var sourceAvailable = true
      var navigationAvailable = true

      let document = QuickSearchDocument(
        title: "Untitled",
        url: nil,
        readSnapshot: {
          guard sourceAvailable else {
            throw QuickSearchDocumentError.unavailable
          }

          return .init(text: "# Plan\nA plan", headings: [.init(title: "Plan", level: 1, lineNumber: 1)])
        },
        gotoLine: { _ in
          guard navigationAvailable else {
            throw QuickSearchDocumentError.unavailable
          }

          XCTFail("Must not navigate to an unavailable document")
        }
      )

      let controller = QuickSearchController(
        effectViewType: NSVisualEffectView.self,
        placeholder: { _ in "Quick Search" },
        accessibilityHelp: "Search",
        filterLabels: filterLabels,
        reportError: { XCTFail($0) },
        openDocument: { _ in XCTFail("Must not open a file while refreshing") }
      )

      controller.present(
        recentURLs: [URL(filePath: "/Notes/Recent Plan.md")],
        document: document,
        screen: try XCTUnwrap(NSScreen.main)
      )

      let window = try XCTUnwrap(controller.window)
      defer { window.orderOut(nil) }

      let view = try XCTUnwrap(window.contentView as? QuickSearchView)
      let field = try XCTUnwrap(view.subviews.compactMap { $0 as? NSTextField }.first)
      let table: NSTableView = try XCTUnwrap(view.firstDescendant())

      field.stringValue = "plan"
      view.controlTextDidChange(Notification(name: NSControl.textDidChangeNotification, object: field))
      try await waitUntil { table.numberOfRows == 3 }

      sourceAvailable = stage == "navigation"
      navigationAvailable = false

      if stage == "refresh" {
        controller.refreshDocument()
      } else {
        XCTAssertTrue(view.control(field, textView: NSTextView(), doCommandBy: #selector(NSResponder.insertNewline(_:))))
      }

      try await waitUntil { table.numberOfRows == 1 && !window.isActivatingResult }
      let cell = try XCTUnwrap(table.view(atColumn: 0, row: 0, makeIfNecessary: true))
      XCTAssertEqual(cell.subviews.compactMap { $0 as? NSTextField }.first?.stringValue, "Recent Plan.md")
      XCTAssertTrue(window.isVisible)
      XCTAssertEqual(field.stringValue, "plan")
      XCTAssertNotNil(field.currentEditor())

      let results: QuickSearchResultsView = try XCTUnwrap(view.firstDescendant())
      XCTAssertTrue(try XCTUnwrap(results.subviews.compactMap { $0 as? NSTextField }.first).isHidden)
    }
  }

  func testUnexpectedFailuresAreLoggedWithoutInlineMessages() async throws {
    var errors: [String] = []
    let readError = CocoaError(.fileReadCorruptFile)
    let openError = CocoaError(.fileReadNoPermission)

    let controller = QuickSearchController(
      effectViewType: NSVisualEffectView.self,
      placeholder: { _ in "Quick Search" },
      accessibilityHelp: "Search",
      filterLabels: filterLabels,
      reportError: { errors.append($0) },
      openDocument: { _ in throw openError }
    )

    controller.present(
      recentURLs: [URL(filePath: "/Notes/Plan.md")],
      locations: .init(urls: [], filenameExtensions: ["md"], showsHiddenFiles: false, errors: ["Grant unavailable"]),
      document: .init(title: "Untitled", url: nil, readSnapshot: { throw readError }, gotoLine: { _ in }),
      screen: try XCTUnwrap(NSScreen.main)
    )

    let window = try XCTUnwrap(controller.window)
    defer { window.orderOut(nil) }

    try await waitUntil { errors.count == 2 }
    XCTAssertEqual(errors, ["Grant unavailable", readError.localizedDescription])
    XCTAssertTrue(window.isVisible)

    let view = try XCTUnwrap(window.contentView as? QuickSearchView)
    XCTAssertTrue(view.control(NSControl(), textView: NSTextView(), doCommandBy: #selector(NSResponder.insertNewline(_:))))
    try await waitUntil { errors.count == 3 && !window.isActivatingResult }
    XCTAssertEqual(errors.last, openError.localizedDescription)

    let table: NSTableView = try XCTUnwrap(view.firstDescendant())
    XCTAssertEqual(table.numberOfRows, 1)
    let results: QuickSearchResultsView = try XCTUnwrap(view.firstDescendant())
    XCTAssertTrue(try XCTUnwrap(results.subviews.compactMap { $0 as? NSTextField }.first).isHidden)
  }
}

extension QuickSearchTests {
  func testReopeningRestoresSelectedQueryAndRefreshesResults() async throws {
    let screen = try XCTUnwrap(NSScreen.main)
    let urls = ["First.md", "Second.md", "Second Draft.md"].map { URL(filePath: "/Notes/\($0)") }

    for activate in [false, true] {
      var opened: [URL] = []
      let controller = QuickSearchController(
        effectViewType: NSVisualEffectView.self,
        placeholder: { _ in "Quick Search" },
        accessibilityHelp: "Search",
        filterLabels: filterLabels,
        reportError: { XCTFail($0) },
        openDocument: { opened.append($0) }
      )

      defer { controller.window?.orderOut(nil) }
      controller.present(recentURLs: Array(urls.prefix(2)), screen: screen)
      let window = try XCTUnwrap(controller.window)
      let view = try XCTUnwrap(window.contentView as? QuickSearchView)
      let field = try XCTUnwrap(view.subviews.compactMap { $0 as? NSTextField }.first)
      let table: NSTableView = try XCTUnwrap(view.firstDescendant())
      XCTAssertEqual(field.stringValue, "")

      let query = " Second "
      field.stringValue = query
      view.controlTextDidChange(Notification(name: NSControl.textDidChangeNotification, object: field))

      if activate {
        try await waitUntil { table.numberOfRows == 1 }
        XCTAssertTrue(view.control(field, textView: NSTextView(), doCommandBy: #selector(NSResponder.insertNewline(_:))))
        try await waitUntil { !window.isVisible }
        XCTAssertEqual(opened, [urls[1]])
      } else {
        window.cancelOperation(nil)
      }

      controller.present(recentURLs: urls, screen: screen)
      let reopened = try XCTUnwrap(controller.window?.contentView as? QuickSearchView)
      let reopenedField = try XCTUnwrap(reopened.subviews.compactMap { $0 as? NSTextField }.first)
      let reopenedTable: NSTableView = try XCTUnwrap(reopened.firstDescendant())
      XCTAssertEqual(reopenedField.stringValue, query)
      XCTAssertEqual(reopenedField.currentEditor()?.selectedRange, NSRange(location: 0, length: query.utf16.count))

      try await waitUntil { reopenedTable.numberOfRows == 2 }
      let titles = (0..<reopenedTable.numberOfRows).compactMap {
        reopenedTable.view(atColumn: 0, row: $0, makeIfNecessary: true)?
          .subviews.compactMap { $0 as? NSTextField }.first?.stringValue
      }

      XCTAssertEqual(titles, ["Second.md", "Second Draft.md"])
      reopenedField.stringValue = ""
      reopened.controlTextDidChange(Notification(name: NSControl.textDidChangeNotification, object: reopenedField))
      controller.window?.cancelOperation(nil)
      controller.present(recentURLs: urls, screen: screen)

      let cleared = try XCTUnwrap(controller.window?.contentView as? QuickSearchView)
      XCTAssertEqual(cleared.subviews.compactMap { $0 as? NSTextField }.first?.stringValue, "")
      let clearedTable: NSTableView = try XCTUnwrap(cleared.firstDescendant())
      XCTAssertEqual(clearedTable.numberOfRows, urls.count)
    }
  }

  func testDiscoveryIncludesFinalPartialBatchForActiveQuery() async throws {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let urls = try (0..<205).map { index in
      let url = directory.appending(path: "Plan-\(index).md")
      try "".write(to: url, atomically: true, encoding: .utf8)
      return url
    }

    let controller = QuickSearchController(
      effectViewType: NSVisualEffectView.self,
      placeholder: { _ in "Quick Search" },
      accessibilityHelp: "Search",
      filterLabels: filterLabels,
      reportError: { XCTFail($0) },
      openDocument: { _ in XCTFail("Discovery must not open a file") }
    )

    controller.present(
      recentURLs: [],
      locations: .init(urls: urls, filenameExtensions: ["md"], showsHiddenFiles: false),
      screen: try XCTUnwrap(NSScreen.main)
    )

    defer {
      controller.window?.orderOut(nil)
    }

    let view = try XCTUnwrap(controller.window?.contentView as? QuickSearchView)
    let field = try XCTUnwrap(view.subviews.compactMap { $0 as? NSTextField }.first)
    let table: NSTableView = try XCTUnwrap(view.firstDescendant())
    field.stringValue = "Plan"
    view.controlTextDidChange(Notification(name: NSControl.textDidChangeNotification, object: field))
    try await waitUntil { table.numberOfRows == urls.count }

    field.stringValue = "Plan-204"
    view.controlTextDidChange(Notification(name: NSControl.textDidChangeNotification, object: field))
    try await waitUntil { table.numberOfRows == 1 }

    let cell = try XCTUnwrap(table.view(atColumn: 0, row: 0, makeIfNecessary: true))
    XCTAssertEqual(cell.subviews.compactMap { $0 as? NSTextField }.first?.stringValue, "Plan-204.md")
  }
}

private extension QuickSearchTests {
  var filterLabels: QuickSearchFilterLabels {
    .init(
      title: "Filter Results",
      all: "All",
      recents: "Recents",
      bookmarks: "Bookmarks",
      headings: "Headings",
      contents: "Contents",
      menuActions: "Menu Actions",
      currentDocument: "Current Document"
    )
  }

  func waitUntil(_ condition: () -> Bool) async throws {
    let deadline = ContinuousClock.now.advanced(by: .seconds(3))

    while !condition(), ContinuousClock.now < deadline {
      try await Task.sleep(for: .milliseconds(10))
    }

    XCTAssertTrue(condition(), "Timed out waiting for search results")
  }
}
