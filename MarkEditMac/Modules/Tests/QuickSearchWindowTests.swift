//
//  QuickSearchWindowTests.swift
//
//  Created by cyan on 10/11/26.
//

import AppKit
import XCTest
@testable import QuickSearchUI

@MainActor
final class QuickSearchWindowTests: XCTestCase {
  func testAcceptedTextDismissesWindow() throws {
    var submittedText: String?
    let window = makeWindow { text in
      submittedText = text
      return true
    }

    defer { window.orderOut(nil) }
    XCTAssertEqual(window.contentView?.layer?.cornerRadius, 20)

    let field = try textField(in: window)
    field.stringValue = " path/to/Notes.md "
    window.makeKeyAndOrderFront(nil)

    XCTAssertTrue(try submit(window))
    XCTAssertEqual(submittedText, " path/to/Notes.md ")
    XCTAssertFalse(window.isVisible)
  }

  func testRejectedTextStaysVisibleAndSelected() throws {
    var submittedText: String?
    let window = makeWindow { text in
      submittedText = text
      return false
    }

    defer { window.orderOut(nil) }
    let field = try textField(in: window)
    field.stringValue = "invalid"
    window.makeKeyAndOrderFront(nil)
    window.makeFirstResponder(field)
    field.currentEditor()?.selectedRange = NSRange(location: 7, length: 0)

    let view = try XCTUnwrap(window.contentView as? QuickSearchView)
    XCTAssertFalse(view.control(field, textView: NSTextView(), doCommandBy: #selector(NSResponder.insertTab(_:))))

    XCTAssertTrue(try submit(window))
    XCTAssertEqual(submittedText, "invalid")
    XCTAssertTrue(window.isVisible)
    XCTAssertEqual(field.stringValue, "invalid")
    XCTAssertEqual(field.currentEditor()?.selectedRange, NSRange(location: 0, length: 7))
  }

  func testResultsScrollWithInternalPaddingAndPartiallyVisibleLastRow() throws {
    let view = QuickSearchResultsView { _ in }
    let window = makeWindow { _ in true }
    defer { window.orderOut(nil) }
    window.contentView = view

    let items = (0..<12).map {
      QuickSearchItem(id: "\($0)", title: "Result \($0)", subtitle: "", iconName: "doc.text")
    }

    let table: NSTableView = try XCTUnwrap(view.firstDescendant())
    let scrollView = try XCTUnwrap(table.enclosingScrollView)

    for (style, count) in [
      (NSScroller.Style.overlay, 0), (.overlay, 2), (.overlay, 0), (.overlay, 8), (.overlay, 12),
      (.legacy, 0), (.legacy, 12), (.legacy, 0), (.legacy, 2),
    ] {
      scrollView.scrollerStyle = style
      view.update(Array(items.prefix(count)), message: nil, preserveSelection: false)
      window.setContentSize(NSSize(width: 640, height: view.preferredHeight))
      view.updateConstraintsForSubtreeIfNeeded()
      view.layoutSubtreeIfNeeded()

      XCTAssertEqual(scrollView.frame.minX, 0)
      XCTAssertEqual(scrollView.frame.maxX, view.bounds.maxX)
      XCTAssertEqual(scrollView.frame.minY, 0)
      XCTAssertEqual(scrollView.frame.maxY, view.bounds.maxY)
      XCTAssertLessThanOrEqual(
        scrollView.contentInsets.top + scrollView.contentInsets.bottom,
        scrollView.contentView.bounds.height
      )

      if count == 0 {
        XCTAssertEqual(scrollView.contentInsets.top, 0)
        XCTAssertEqual(scrollView.contentInsets.bottom, 0)
        continue
      }

      XCTAssertEqual(scrollView.contentInsets.top, 8)
      XCTAssertEqual(scrollView.contentInsets.bottom, 8)

      let clipView = scrollView.contentView
      XCTAssertEqual(clipView.frame.minY, 0)
      XCTAssertEqual(clipView.frame.maxY, scrollView.bounds.maxY)
      clipView.scroll(to: NSPoint(x: -8, y: -8))
      scrollView.reflectScrolledClipView(clipView)
      XCTAssertEqual(table.convert(table.rect(ofRow: 0), to: view).minX, 8)

      if count == 2 {
        XCTAssertTrue(table.visibleRect.contains(table.rect(ofRow: 1)))
      } else {
        let lastRow = table.rect(ofRow: 7)
        XCTAssertEqual(table.visibleRect.intersection(lastRow).height, 26, accuracy: 1)

        let scroller = try XCTUnwrap(scrollView.verticalScroller)
        XCTAssertEqual(scrollView.convert(scroller.frame, to: view).maxX, view.bounds.maxX)

        clipView.scroll(to: NSPoint(x: -8, y: 20))
        scrollView.reflectScrolledClipView(clipView)
        XCTAssertEqual(table.convert(clipView.bounds, from: clipView).minY, 20)

        table.scrollRowToVisible(count - 1)
        XCTAssertTrue(table.visibleRect.contains(table.rect(ofRow: count - 1)))
      }
    }
  }

  func testResultTitlesStayOnOneLineWithoutHidingSubtitles() throws {
    let view = QuickSearchResultsView { _ in }
    let window = makeWindow { _ in true }
    defer { window.orderOut(nil) }
    window.contentView = view

    let longTitle = String(repeating: "A long matching snippet ", count: 20)
    let titles = [
      ("Short title", "Short title"),
      (longTitle, longTitle),
      ("First line\nSecond line", "First line Second line"),
      ("First line\u{2028}Second line", "First line Second line"),
      ("First line\u{2029}Second line", "First line Second line"),
      ("First line\r\nSecond line", "First line  Second line"),
    ]

    let subtitle = "Documents/Notes.md:42"
    let items = titles.enumerated().map {
      QuickSearchItem(
        id: "\($0.offset)",
        title: $0.element.0,
        subtitle: subtitle,
        iconName: "text.alignleft",
        highlightedRanges: [NSRange(location: $0.element.0.utf16.count - 5, length: 5)]
      )
    }

    view.update(items, message: nil, preserveSelection: false)
    let table: NSTableView = try XCTUnwrap(view.firstDescendant())

    for width in [640.0, 320.0] {
      window.setContentSize(NSSize(width: width, height: view.preferredHeight))
      view.updateConstraintsForSubtreeIfNeeded()
      view.layoutSubtreeIfNeeded()

      var singleLineHeight: Double?

      for row in items.indices {
        let cell = try XCTUnwrap(table.view(atColumn: 0, row: row, makeIfNecessary: true))
        cell.layoutSubtreeIfNeeded()

        let fields = cell.subviews.compactMap { $0 as? NSTextField }
        let titleField = try XCTUnwrap(fields.first)
        let subtitleField = try XCTUnwrap(fields.last)

        if row == 0 {
          singleLineHeight = titleField.frame.height
        }

        XCTAssertEqual(titleField.frame.height, try XCTUnwrap(singleLineHeight), accuracy: 0.5, "Row \(row)")
        XCTAssertEqual(titleField.stringValue, titles[row].1)
        XCTAssertEqual(cell.accessibilityLabel(), "\(items[row].title), \(subtitle)")
        XCTAssertEqual(
          titleField.attributedStringValue.attribute(
            .font, at: items[row].highlightedRanges[0].location, effectiveRange: nil
          ) as? NSFont,
          .systemFont(ofSize: 15, weight: .semibold)
        )
        XCTAssertEqual(subtitleField.stringValue, subtitle)
        XCTAssertFalse(subtitleField.isHidden)
        XCTAssertTrue(cell.bounds.contains(subtitleField.frame), "Row \(row)")
        XCTAssertFalse(titleField.frame.intersects(subtitleField.frame), "Row \(row)")
      }
    }
  }
}

extension QuickSearchWindowTests {
  func testFolderSubtitleKeepsMatchVisibleWithoutChangingBreadcrumbAsHighlightsChange() throws {
    let view = QuickSearchResultsView { _ in }
    let window = makeWindow { _ in true }
    defer { window.orderOut(nil) }
    window.contentView = view

    let path = String(repeating: "Long ancestor \u{203A} ", count: 8)
      + "Editor \u{203A} " + String(repeating: "Nested folder \u{203A} ", count: 8) + "LibreMac.md"
    let focus = (path as NSString).range(of: "Editor")

    for width in [640.0, 320.0] {
      var previousText: String?
      for length in [2, 6] {
        let items = (0...1).map {
          QuickSearchItem(
            id: "\($0)",
            title: "LibreMac.md",
            subtitle: path,
            iconName: "bookmark",
            subtitleHighlightedRanges: [NSRange(location: focus.location, length: length)],
            subtitleFocusRange: focus
          )
        }

        view.update(items, message: nil, preserveSelection: false)
        window.setContentSize(NSSize(width: width, height: view.preferredHeight))
        view.layoutSubtreeIfNeeded()

        let table: NSTableView = try XCTUnwrap(view.firstDescendant())
        for row in 0...1 {
          let cell = try XCTUnwrap(table.view(atColumn: 0, row: row, makeIfNecessary: true))
          cell.layoutSubtreeIfNeeded()

          let field = try XCTUnwrap(cell.subviews.compactMap { $0 as? NSTextField }.last)
          let text = field.attributedStringValue
          let match = (text.string as NSString).range(of: "Editor")
          XCTAssertNotEqual(match.location, NSNotFound)
          XCTAssertTrue(text.string.hasSuffix("LibreMac.md"))
          XCTAssertLessThanOrEqual(text.size().width, try XCTUnwrap(field.cell).drawingRect(forBounds: field.bounds).width)
          XCTAssertEqual(cell.toolTip, path)
          XCTAssertEqual(
            text.attribute(.font, at: match.location, effectiveRange: nil) as? NSFont,
            .systemFont(ofSize: 12, weight: .semibold)
          )

          XCTAssertEqual(
            text.attribute(.foregroundColor, at: match.location, effectiveRange: nil) as? NSColor,
            row == 0 ? .white : .labelColor
          )

          if let previousText {
            XCTAssertEqual(text.string, previousText)
          }

          previousText = text.string
        }
      }
    }

    let gap = String(repeating: "W", count: 80)
    for (folder, matches, nestedCount) in [
      ("Editor", ["Editor"], 20),
      (String(repeating: "Long ", count: 30) + "Editor" + String(repeating: " tail", count: 30), ["Editor"], 20),
      ("a\(gap)b\(gap)c", ["a", "b", "c"], 20),
      ("Archive\nEditor", ["Editor"], 0),
      ("A\r\n\u{0085}\u{2028}\u{2029}Editor", ["Editor"], 20),
    ] {
      let path = folder + " \u{203A} " + String(repeating: "Nested \u{203A} ", count: nestedCount) + "LibreMac.md"
      let ranges = matches.map { (folder as NSString).range(of: $0) }
      let item = QuickSearchItem(
        id: "file",
        title: "LibreMac.md",
        subtitle: path,
        iconName: "bookmark",
        subtitleHighlightedRanges: ranges,
        subtitleFocusRange: NSRange(location: 0, length: folder.utf16.count)
      )

      view.update([item], message: nil, preserveSelection: false)
      window.setContentSize(NSSize(width: 320, height: view.preferredHeight))
      view.layoutSubtreeIfNeeded()

      let table: NSTableView = try XCTUnwrap(view.firstDescendant())
      let cell = try XCTUnwrap(table.view(atColumn: 0, row: 0, makeIfNecessary: true))
      cell.layoutSubtreeIfNeeded()

      let field = try XCTUnwrap(cell.subviews.compactMap { $0 as? NSTextField }.last)
      let text = field.attributedStringValue
      let displayedMatches = matches.map { (text.string as NSString).range(of: $0) }

      XCTAssertTrue(displayedMatches.allSatisfy { $0.location != NSNotFound })
      XCTAssertLessThanOrEqual(text.size().width, try XCTUnwrap(field.cell).drawingRect(forBounds: field.bounds).width)
      XCTAssertEqual(cell.toolTip, path)
      XCTAssertEqual(cell.accessibilityLabel(), "\(item.title), \(path)")
      XCTAssertNil(text.string.rangeOfCharacter(from: .newlines))

      text.enumerateAttribute(.font, in: NSRange(location: 0, length: text.length)) { font, range, _ in
        let isMatch = displayedMatches.contains { NSIntersectionRange(range, $0).length > 0 }
        let weight: NSFont.Weight = isMatch ? .semibold : .regular
        XCTAssertEqual(font as? NSFont, .systemFont(ofSize: 12, weight: weight))
      }
    }
  }

  func testResultsRouteQuerySelectionAndDismissalWithoutSubmittingText() async throws {
    var query = ""
    var activatedID: String?
    var dismissals = 0
    let screen = try XCTUnwrap(NSScreen.main)
    let window = QuickSearchWindow(
      effectViewType: NSVisualEffectView.self,
      relativeTo: screen.visibleFrame,
      visibleFrame: screen.visibleFrame,
      placeholder: "Quick Search",
      accessibilityHelp: "Search",
      iconName: "magnifyingglass",
      results: .init(
        onQueryChange: { query = $0 },
        onActivate: { activatedID = $0 },
        onDismiss: { dismissals += 1 }
      )
    )

    defer { window.orderOut(nil) }
    window.orderOut(nil)
    XCTAssertEqual(dismissals, 0)

    let items = ["first", "second"].map {
      QuickSearchItem(id: $0, title: $0, subtitle: "", iconName: "doc.text")
    }

    let originalTop = window.frame.maxY
    window.updateResults(items)
    XCTAssertEqual(window.frame.maxY, originalTop)

    window.makeKeyAndOrderFront(nil)
    window.focusInput()

    let view = try XCTUnwrap(window.contentView as? QuickSearchView)
    XCTAssertEqual(view.layer?.cornerRadius, 20)
    view.layoutSubtreeIfNeeded()

    let table: NSTableView = try XCTUnwrap(view.firstDescendant())
    window.updateResults(items.reversed())
    XCTAssertEqual(table.selectedRow, 0)
    window.updateResults(items)

    let cell = try XCTUnwrap(table.view(atColumn: 0, row: 0, makeIfNecessary: true))
    cell.layoutSubtreeIfNeeded()

    let iconBackground = try XCTUnwrap(cell.subviews.first { $0.layer?.cornerRadius == 6 })
    XCTAssertEqual(iconBackground.frame.size, NSSize(width: 28, height: 28))
    XCTAssertEqual(iconBackground.layer?.cornerCurve, .continuous)

    let row = try XCTUnwrap(table.rowView(atRow: 0, makeIfNecessary: true))
    row.layoutSubtreeIfNeeded()
    let selection = try XCTUnwrap(row.subviews.first { $0.layer?.cornerRadius == 12 })
    XCTAssertEqual(selection.layer?.cornerCurve, .continuous)
    XCTAssertEqual(selection.frame, row.bounds.insetBy(dx: 0, dy: 2))
    XCTAssertFalse(selection.isHidden)

    let unselectedCell = try XCTUnwrap(table.view(atColumn: 0, row: 1, makeIfNecessary: true))
    let unselectedTitle = try XCTUnwrap(unselectedCell.subviews.compactMap { $0 as? NSTextField }.first)

    for (appearance, component) in [(NSAppearance.Name.aqua, 0.0), (.darkAqua, 1.0)] {
      window.appearance = NSAppearance(named: appearance)
      window.displayIfNeeded()
      let color = try XCTUnwrap(unselectedTitle.attributedStringValue.attribute(
        .foregroundColor, at: 0, effectiveRange: nil
      ) as? NSColor)
      XCTAssertEqual(try XCTUnwrap(color.usingColorSpace(.sRGB)).redComponent, component, accuracy: 0.1)
      XCTAssertEqual(color.alphaComponent, 0.75, accuracy: 0.01)
    }

    let field = try textField(in: window)
    field.stringValue = "second"
    view.controlTextDidChange(Notification(name: NSControl.textDidChangeNotification, object: field))
    XCTAssertEqual(query, "second")

    XCTAssertTrue(view.control(field, textView: NSTextView(), doCommandBy: #selector(NSResponder.moveDown(_:))))
    XCTAssertTrue(selection.isHidden)
    window.updateResults(items.reversed())
    XCTAssertTrue(view.control(field, textView: NSTextView(), doCommandBy: #selector(NSResponder.insertNewline(_:))))
    XCTAssertEqual(activatedID, "second")
    XCTAssertTrue(window.isVisible)
    XCTAssertNotNil(field.currentEditor())

    let results: QuickSearchResultsView = try XCTUnwrap(view.firstDescendant())
    window.updateResults([])

    if !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
      XCTAssertGreaterThan(window.frame.height, 48)
    }

    window.updateResults(items)
    window.updateResults([])
    try await waitForResize(window, height: 48)
    XCTAssertTrue(results.isHidden)
    XCTAssertEqual(window.frame.height, 48)
    XCTAssertEqual(window.frame.maxY, originalTop)
    XCTAssertNotNil(field.currentEditor())

    window.updateResults([], message: "Unable to read the document")
    try await waitForResize(window, height: 112)
    XCTAssertFalse(results.isHidden)
    XCTAssertGreaterThan(window.frame.height, 48)

    window.cancelOperation(nil)
    XCTAssertEqual(dismissals, 1)
    XCTAssertFalse(window.isVisible)

    window.orderOut(nil)
    window.cancelOperation(nil)
    XCTAssertEqual(dismissals, 1)

    window.makeKeyAndOrderFront(nil)
    window.resignKey()
    XCTAssertEqual(dismissals, 2)
    XCTAssertFalse(window.isVisible)

    window.makeKeyAndOrderFront(nil)
    window.isActivatingResult = true
    window.resignKey()
    XCTAssertEqual(dismissals, 2)
    XCTAssertFalse(window.isVisible)

    window.isActivatingResult = false
    window.orderOut(nil)
    XCTAssertEqual(dismissals, 2)

    window.makeKeyAndOrderFront(nil)
    window.cancelOperation(nil)
    XCTAssertEqual(dismissals, 3)
  }
}

extension QuickSearchWindowTests {
  func testTabPresentsFilterMenuWithoutSelectingText() throws {
    let menu = NSMenu(title: "Filter Results")
    menu.autoenablesItems = false
    menu.addItem(withTitle: "All", action: nil, keyEquivalent: "")
    menu.addItem(withTitle: "Headings", action: nil, keyEquivalent: "").state = .on

    let screen = try XCTUnwrap(NSScreen.main)
    let window = QuickSearchWindow(
      effectViewType: NSVisualEffectView.self,
      relativeTo: screen.visibleFrame,
      visibleFrame: screen.visibleFrame,
      placeholder: "Quick Search for files, text, and commands",
      accessibilityHelp: "Search",
      iconName: "magnifyingglass",
      results: .init(filterMenu: menu, onQueryChange: { _ in }, onActivate: { _ in }, onDismiss: {})
    )

    defer { window.orderOut(nil) }
    window.makeKeyAndOrderFront(nil)
    window.focusInput()

    let view = try XCTUnwrap(window.contentView as? QuickSearchView)
    let field = try XCTUnwrap(view.subviews.compactMap { $0 as? NSTextField }.first)
    field.stringValue = "plan"
    let editor = try XCTUnwrap(field.currentEditor() as? NSTextView)
    editor.selectedRange = NSRange(location: 2, length: 0)

    let opened = expectation(forNotification: NSMenu.didBeginTrackingNotification, object: menu)
    let timer = Timer(
      timeInterval: 0.1,
      target: self,
      selector: #selector(checkHighlightedFilter(_:)),
      userInfo: menu,
      repeats: false
    )

    RunLoop.main.add(timer, forMode: .eventTracking)
    defer { timer.invalidate() }

    XCTAssertTrue(view.control(field, textView: editor, doCommandBy: #selector(NSResponder.insertTab(_:))))
    wait(for: [opened], timeout: 1)
    XCTAssertTrue(window.isVisible)
    XCTAssertNotNil(field.currentEditor())
    XCTAssertEqual(field.stringValue, "plan")
    XCTAssertEqual(editor.selectedRange, NSRange(location: 2, length: 0))
  }
}

private extension QuickSearchWindowTests {
  @objc func checkHighlightedFilter(_ timer: Timer) {
    guard let menu = timer.userInfo as? NSMenu else {
      XCTFail("Missing filter menu")
      return
    }

    XCTAssertNotNil(menu.highlightedItem)
    XCTAssertEqual(menu.highlightedItem, menu.items.first { $0.state == .on })
    menu.cancelTracking()
  }

  func waitForResize(_ window: NSWindow, height: Double) async throws {
    let top = window.frame.maxY
    let deadline = ContinuousClock.now.advanced(by: .seconds(2))

    while window.frame.height != height, ContinuousClock.now < deadline {
      XCTAssertEqual(window.frame.maxY, top, accuracy: 1)
      try await Task.sleep(for: .milliseconds(10))
    }

    XCTAssertEqual(window.frame.height, height)
    XCTAssertEqual(window.frame.maxY, top, accuracy: 1)
  }

  func makeWindow(handler: @escaping (String) -> Bool) -> QuickSearchWindow {
    QuickSearchWindow(
      effectViewType: NSVisualEffectView.self,
      relativeTo: CGRect(x: 0, y: 0, width: 800, height: 600),
      placeholder: "Open",
      accessibilityHelp: "Enter a value",
      iconName: "magnifyingglass",
      handler: handler
    )
  }

  func textField(in window: QuickSearchWindow) throws -> NSTextField {
    let view = try XCTUnwrap(window.contentView as? QuickSearchView)
    return try XCTUnwrap(view.subviews.compactMap { $0 as? NSTextField }.first)
  }

  func submit(_ window: QuickSearchWindow) throws -> Bool {
    let view = try XCTUnwrap(window.contentView as? QuickSearchView)
    return view.control(
      try textField(in: window),
      textView: NSTextView(),
      doCommandBy: #selector(NSResponder.insertNewline(_:))
    )
  }
}
