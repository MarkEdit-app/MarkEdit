//
//  FileVersionConcurrencyTests.swift
//

import MarkEditKit
import XCTest

#if os(macOS)
@MainActor
final class FileVersionConcurrencyTests: XCTestCase {
  func testLocalContentsKeepVersionOnCallerActor() async throws {
    let fixture = try Fixture()
    defer { fixture.remove() }

    XCTAssertFalse(fixture.version.needsDownloading)
    let succeeded = await fixture.version.fetchLocalContents()
    XCTAssertTrue(succeeded)
    XCTAssertFalse(fixture.version.needsDownloading)
    XCTAssertEqual(try String(contentsOf: fixture.version.url, encoding: .utf8), "version")
  }

  func testRemovalPreservesDocumentContent() async throws {
    let fixture = try Fixture()
    defer { fixture.remove() }

    try await fixture.version.removeFromDisk(for: fixture.documentURL)
    XCTAssertTrue((NSFileVersion.otherVersionsOfItem(at: fixture.documentURL) ?? []).isEmpty)
    XCTAssertEqual(try String(contentsOf: fixture.documentURL, encoding: .utf8), "current")
  }

  func testMissingVersionPreservesFoundationRemovalResult() async throws {
    let fixture = try Fixture()
    defer { fixture.remove() }
    try fixture.version.remove()

    let expectedError: NSError?
    do {
      try fixture.version.remove()
      expectedError = nil
    } catch {
      expectedError = error as NSError
    }

    do {
      try await fixture.version.removeFromDisk(for: fixture.documentURL)
      XCTAssertNil(expectedError)
    } catch {
      let expectedError = try XCTUnwrap(expectedError)
      XCTAssertEqual((error as NSError).domain, expectedError.domain)
      XCTAssertEqual((error as NSError).code, expectedError.code)
    }
  }

  func testRemovalDoesNotDeleteOtherVersions() async throws {
    let fixture = try Fixture()
    defer { fixture.remove() }
    let contentsURL = fixture.directory.appending(path: "other-version.md")
    try Data("other version".utf8).write(to: contentsURL)
    let otherVersion = try NSFileVersion.addOfItem(
      at: fixture.documentURL,
      withContentsOf: contentsURL,
      options: []
    )

    defer { try? otherVersion.remove() }
    try await fixture.version.removeFromDisk(for: fixture.documentURL)

    let remaining = NSFileVersion.otherVersionsOfItem(at: fixture.documentURL) ?? []
    XCTAssertEqual(remaining.count, 1)
    XCTAssertEqual(remaining.first?.url, otherVersion.url)
    XCTAssertEqual(try String(contentsOf: otherVersion.url, encoding: .utf8), "other version")
  }
}

private extension FileVersionConcurrencyTests {
  struct Fixture {
    let directory: URL
    let documentURL: URL
    let version: NSFileVersion

    init() throws {
      directory = URL(filePath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appending(path: ".build/FileVersionTests/\(UUID().uuidString)", directoryHint: .isDirectory)
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

      documentURL = directory.appending(path: "document.md")
      let contentsURL = directory.appending(path: "version.md")
      try Data("current".utf8).write(to: documentURL)
      try Data("version".utf8).write(to: contentsURL)

      version = try NSFileVersion.addOfItem(
        at: documentURL,
        withContentsOf: contentsURL,
        options: []
      )
    }

    func remove() {
      try? version.remove()
      try? FileManager.default.removeItem(at: directory)
    }
  }
}

#endif
