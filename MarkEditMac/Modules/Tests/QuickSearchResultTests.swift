//
//  QuickSearchResultTests.swift
//
//  Created by cyan on 10/11/26.
//

import XCTest
@testable import QuickSearchCore

final class QuickSearchResultTests: XCTestCase {
  func testAllRanksHeadingsThenContentBeforeGlobalMatches() throws {
    let recent = URL(filePath: "/Notes/Release Plan.md")
    let exact = URL(filePath: "/Notes/Plan.md")
    let prefix = URL(filePath: "/Archive/Planning.md")

    let actions = [
      MenuActionSearchResult.Action(indices: [0, 0], titles: ["File", "Plan"]),
      .init(indices: [0, 1], titles: ["File", "Plan Ahead"]),
      .init(indices: [1, 0], titles: ["Planning", "Overview"]),
      .init(indices: [2, 0], titles: ["Edit", "Release Plan"]),
    ]

    let results = try QuickSearchResult.search(
      "plan",
      filter: .all,
      recentURLs: [recent, exact],
      bookmarkedURLs: [prefix, exact],
      snapshot: .init(
        text: Array(repeating: "A plan", count: 100).joined(separator: "\n"),
        headings: [.init(title: "Personal Ledger And Notes", level: 1, lineNumber: 101)]
      ),
      menuActions: actions
    )

    let expected = ["heading:101"] + (1...100).map { "line:\($0)" } + [
      "file:\(exact.absoluteString)", "menu:0.0", "file:\(prefix.absoluteString)", "menu:0.1",
      "file:\(recent.absoluteString)", "menu:2.0", "menu:1.0",
    ]

    XCTAssertEqual(results.map(\.id), expected)
    XCTAssertEqual(Set(results.map(\.id)).count, results.count)
  }

  func testFuzzyMatchingPrefersWordStartsWithoutOverridingContiguousMatches() throws {
    for (query, abbreviation, scattered) in [
      ("sp", "Show Preview", "Setup"),
      ("nt", "New Tab", "North"),
      ("sp", "Show-Preview", "Setup"),
    ] {
      let urls = [scattered, abbreviation, query.uppercased()].map { URL(filePath: "/Notes/\($0).md") }
      let matches = try FileSearchResult.search(query, urls: urls)
      XCTAssertEqual(matches.map(\.url), [urls[2], urls[1], urls[0]])

      let match = try XCTUnwrap(FuzzyMatcher.match(query, text: abbreviation))
      XCTAssertEqual(match.rank, 3)
      XCTAssertEqual(
        match.ranges.map { (abbreviation as NSString).substring(with: $0) }.joined().lowercased(),
        query
      )
    }

    let compact = try XCTUnwrap(FuzzyMatcher.match("sp", text: "Setup"))
    let distant = try XCTUnwrap(FuzzyMatcher.match("sp", text: "Something very far from Preview"))
    XCTAssertLessThan(compact.penalty, distant.penalty)
    XCTAssertLessThan(try XCTUnwrap(FuzzyMatcher.match("sp", text: "Spell")).rank, compact.rank)
    XCTAssertLessThan(try XCTUnwrap(FuzzyMatcher.match("sp", text: "Inspect")).rank, compact.rank)
  }

  func testHeadingMarkersMatchLevelsAndPreserveTitleHighlights() throws {
    let headings = (1...3).map {
      QuickSearchHeading(title: "\u{1F4C4} R\u{E9}sum\u{E9} Plan", level: $0, lineNumber: $0)
    }

    XCTAssertEqual(try HeadingSearchResult.search("", headings: headings.reversed()).map(\.heading.level), [1, 2, 3])
    XCTAssertEqual(try HeadingSearchResult.search("#", headings: headings).map(\.heading.level), [1, 2, 3])

    let matches = try HeadingSearchResult.search("##", headings: headings)
    XCTAssertEqual(matches.map(\.heading.level), [2, 3])
    XCTAssertTrue(matches.allSatisfy { $0.match.ranges.isEmpty })

    let result = try XCTUnwrap(HeadingSearchResult.search("## rp", headings: headings).first)
    XCTAssertEqual(result.heading.level, 2)

    let highlights = result.match.ranges.map {
      (result.heading.title as NSString).substring(with: $0)
    }
    XCTAssertEqual(highlights.joined(), "RP")

    let literalMatches = try HeadingSearchResult.search("C#", headings: [
      .init(title: "C# guide", level: 1, lineNumber: 1),
      .init(title: "C#", level: 6, lineNumber: 2),
    ])

    XCTAssertEqual(literalMatches.map(\.heading.title), ["C#", "C# guide"])
    XCTAssertEqual(literalMatches.map(\.match.rank), [0, 1])
    XCTAssertEqual(literalMatches.map(\.match.ranges), Array(repeating: [NSRange(location: 0, length: 2)], count: 2))
  }

  func testLongFuzzyMatchesPreserveAlignmentAndHonorCancellation() async throws {
    let repeated = String(repeating: "a", count: 64_000)

    for query in ["ax", "aax"] {
      let start = ContinuousClock.now
      XCTAssertNil(try FuzzyMatcher.match(query, text: repeated))

      let match = try XCTUnwrap(FuzzyMatcher.match(query, text: repeated + "x"))
      XCTAssertEqual(match.rank, 2)
      XCTAssertEqual(match.penalty, repeated.count + 1 - query.count)
      XCTAssertEqual(
        match.ranges,
        [NSRange(location: repeated.count + 1 - query.count, length: query.count)]
      )
      XCTAssertLessThan(start.duration(to: .now), .seconds(2))
    }

    let task = Task {
      while !Task.isCancelled {
        await Task.yield()
      }

      return try FuzzyMatcher.match("ax", text: repeated)
    }

    task.cancel()
    do {
      _ = try await task.value
      XCTFail("Expected cancellation")
    } catch is CancellationError {
      // Expected even when cancellation happens before matching starts
    }
  }

  func testContentMatchesUseEditorLinesAndOriginalHighlights() throws {
    let text = "before\r\n\r\nPLAN \u{1F4C4}\rnext\nlast plan\u{2028}on the same line"
    let matches = try ContentSearchResult.search("plan", text: text)
    XCTAssertEqual(matches.map(\.lineNumber), [3, 5])
    XCTAssertEqual(matches.map { ($0.snippet as NSString).substring(with: $0.highlightedRange) }, ["PLAN", "plan"])
    XCTAssertTrue(try ContentSearchResult.search("", text: text).isEmpty)
    XCTAssertTrue(try ContentSearchResult.search("pln", text: text).isEmpty)

    let longLine = String(repeating: "\u{1F4C4}", count: 100) + "plan" + String(repeating: "tail", count: 100)
    let match = try XCTUnwrap(ContentSearchResult.search("plan", text: longLine).first)
    XCTAssertEqual((match.snippet as NSString).substring(with: match.highlightedRange), "plan")
    XCTAssertTrue(match.snippet.hasPrefix("\u{2026}"))
    XCTAssertTrue(match.snippet.hasSuffix("\u{2026}"))
  }

  func testDiscoveryRespectsGrantsHiddenFilesPackagesAndSymlinks() async throws {
    let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let folder = root.appending(path: "Granted")
    let nested = folder.appending(path: "Nested")
    let bundle = folder.appending(path: "Notes.textbundle")
    let outside = root.appending(path: "Outside")

    for directory in [nested, bundle, outside] {
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    for path in [
      "Granted/Plan.md", "Granted/.hidden.md", "Granted/Nested/Ideas.txt",
      "Granted/Notes.textbundle/text.md", "Outside/Secret.md", "Direct.md",
    ] {
      try "text".write(to: root.appending(path: path), atomically: true, encoding: .utf8)
    }

    try Data([0, 1, 2]).write(to: folder.appending(path: "image.bin"))
    let customNames = ["Upper.QUICKSEARCHTEST", "Lower.quicksearchtest", "Mixed.QuIcKsEaRcHtEsT"]

    for name in customNames {
      try Data([0, 1, 2]).write(to: folder.appending(path: name))
    }

    try FileManager.default.createSymbolicLink(at: folder.appending(path: "Link"), withDestinationURL: outside)

    for showsHiddenFiles in [false, true] {
      let collector = DiscoveryCollector()
      try await FileDiscovery.scan(.init(
        urls: [folder, nested, root.appending(path: "Direct.md"), root.appending(path: "Missing")],
        filenameExtensions: ["MD", "QuIcKsEaRcHtEsT"],
        showsHiddenFiles: showsHiddenFiles
      )) {
        await collector.append($0)
      }

      let batch = await collector.batch
      var expected = Set(["Plan.md", "Ideas.txt", "Notes.textbundle", "Direct.md"] + customNames)
      if showsHiddenFiles {
        expected.insert(".hidden.md")
      }

      XCTAssertEqual(Set(batch.urls.map(\.lastPathComponent)), expected)
      XCTAssertEqual(batch.urls.count, expected.count)
      XCTAssertEqual(batch.errors.count, 1)
    }
  }

  func testDiscoveryHonorsCancellation() async {
    let collector = DiscoveryCollector()
    let task = Task {
      while !Task.isCancelled {
        await Task.yield()
      }

      try await FileDiscovery.scan(.init(
        urls: [URL(filePath: "/missing")],
        filenameExtensions: [],
        showsHiddenFiles: false
      )) {
        await collector.append($0)
      }
    }

    task.cancel()
    do {
      try await task.value
      XCTFail("Expected cancellation")
    } catch is CancellationError {
      let batch = await collector.batch
      XCTAssertTrue(batch.urls.isEmpty)
      XCTAssertTrue(batch.errors.isEmpty)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
}

extension QuickSearchResultTests {
  func testDiscoveryBatchesDirectRootsAndDirectoryContents() async throws {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let urls = try (0..<205).map { index in
      let isBundle = index.isMultiple(of: 2)
      let url = directory.appending(path: "Note \(index).\(isBundle ? "textbundle" : "md")")
      if isBundle {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
      } else {
        try "text".write(to: url, atomically: true, encoding: .utf8)
      }

      return url
    }

    for roots in [urls, [directory]] {
      let collector = DiscoveryCollector()
      try await FileDiscovery.scan(.init(urls: roots, filenameExtensions: ["md"], showsHiddenFiles: false)) {
        await collector.append($0)
      }

      let batch = await collector.batch
      let batchSizes = await collector.batchSizes
      XCTAssertEqual(batch.urls.map(\.lastPathComponent).sorted(), urls.map(\.lastPathComponent).sorted())
      XCTAssertTrue(batch.errors.isEmpty)
      XCTAssertGreaterThanOrEqual(batchSizes.count, 3)
      XCTAssertTrue(batchSizes.allSatisfy { $0 <= 100 }, "Batch sizes: \(batchSizes)")
    }
  }

  func testFilenameRankingAndRecentDeduplication() throws {
    let names = ["Planning.md", "ProjectPlan.md", "Plan.md", "Personal Ledger And Notes.md"]
    let urls = names.map { URL(filePath: "/Notes/\($0)") }
    let results = try FileSearchResult.search("plan", urls: urls)
    XCTAssertEqual(results.map(\.url.lastPathComponent), [names[2], names[0], names[1], names[3]])
    XCTAssertTrue(try FileSearchResult.search("xyz", urls: urls).isEmpty)
    XCTAssertEqual(try FileSearchResult.search("", urls: urls + urls).map(\.url), urls)
  }

  func testFuzzyHighlightsUseOriginalUTF16Ranges() throws {
    XCTAssertEqual(try FuzzyMatcher.match("Release", text: "Release.Plan")?.rank, 1)
    XCTAssertEqual(try FuzzyMatcher.match("Release", text: "Release.Plan", matchFileStem: true)?.rank, 0)

    for (filename, query, highlighted) in [
      ("\u{1F4C4} R\u{E9}sum\u{E9}.md", "resume", "R\u{E9}sum\u{E9}"),
      ("Re\u{301}sume\u{301}.md", "resume", "Re\u{301}sume\u{301}"),
      ("Stra\u{DF}e.md", "strasse", "Stra\u{DF}e"),
      ("Project Plan.md", "pp", "PP"),
      ("Check Spelling While Typing", "cswt", "CSWT"),
    ] {
      let match = try XCTUnwrap(FuzzyMatcher.match(query, text: filename, matchFileStem: true))
      XCTAssertEqual(
        match.ranges.map { (filename as NSString).substring(with: $0) }.joined(),
        highlighted
      )
    }
  }

  func testFiltersRespectSourcesAndEmptyQueries() throws {
    let shared = URL(filePath: "/Notes/Plan.md")
    let recent = URL(filePath: "/Notes/Release Plan.md")
    let exactBookmark = URL(filePath: "/Archive/Plan.txt")
    let bookmarked = URL(filePath: "/Notes/Plan Bookmark.md")

    let snapshot = QuickSearchDocumentSnapshot(
      text: "# Plan\nA plan",
      headings: [.init(title: "Plan", level: 1, lineNumber: 1)]
    )

    let recentIDs = [shared, recent].map { "file:\($0.absoluteString)" }
    let bookmarkIDs = [shared, exactBookmark, bookmarked].map { "file:\($0.absoluteString)" }
    let actions = [MenuActionSearchResult.Action(indices: [0, 0], titles: ["File", "Plan"])]

    let cases: [(String, QuickSearchFilter, [String])] = [
      ("plan", .all, [
        "heading:1", "line:2", recentIDs[0], bookmarkIDs[1], "menu:0.0", bookmarkIDs[2], recentIDs[1],
      ]),
      ("plan", .recents, recentIDs),
      ("plan", .bookmarks, bookmarkIDs),
      ("plan", .headings, ["heading:1"]),
      ("plan", .contents, ["line:1", "line:2"]),
      ("plan", .menuActions, ["menu:0.0"]),
      ("", .all, recentIDs + ["heading:1"]),
      ("", .recents, recentIDs),
      ("", .bookmarks, bookmarkIDs),
      ("", .headings, ["heading:1"]),
      ("", .contents, []),
      ("", .menuActions, ["menu:0.0"]),
    ]

    for (query, filter, expected) in cases {
      for input in [query, " \t\(query)\r\n"] {
        let results = try QuickSearchResult.search(
          input,
          filter: filter,
          recentURLs: [shared, recent],
          bookmarkedURLs: [shared, exactBookmark, bookmarked],
          snapshot: snapshot,
          menuActions: actions
        )

        XCTAssertEqual(results.map(\.id), expected, "\(input.debugDescription), \(filter)")
      }
    }
  }

  func testEmptyQueryLimitsRecentsWithoutLimitingSearchOrBookmarks() throws {
    let urls = (1...50).map { URL(filePath: "/Notes/Plan \($0).md") }
    let ids = urls.map { "file:\($0.absoluteString)" }

    let snapshot = QuickSearchDocumentSnapshot(
      text: "# Overview",
      headings: [.init(title: "Overview", level: 1, lineNumber: 1)]
    )

    let cases: [(String, QuickSearchFilter, [String])] = [
      ("", .all, Array(ids.prefix(5)) + ["heading:1"]),
      ("", .recents, Array(ids.prefix(5))),
      ("plan", .all, ids),
      ("plan", .recents, ids),
      ("", .bookmarks, ids),
    ]

    for (query, filter, expected) in cases {
      for input in [query, " \t\(query)\r\n"] {
        let results = try QuickSearchResult.search(
          input,
          filter: filter,
          recentURLs: urls,
          bookmarkedURLs: urls,
          snapshot: snapshot
        )

        XCTAssertEqual(results.map(\.id), expected, "\(input.debugDescription), \(filter)")
      }
    }
  }
}

private actor DiscoveryCollector {
  var batch = FileDiscovery.Batch()
  var batchSizes: [Int] = []

  func append(_ batch: FileDiscovery.Batch) {
    self.batch.urls.append(contentsOf: batch.urls)
    self.batch.errors.append(contentsOf: batch.errors)
    batchSizes.append(batch.urls.count)
  }
}
