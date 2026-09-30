//
//  MoveFileTests.swift
//

import MarkEditKit
import XCTest

@MainActor
final class MoveFileTests: XCTestCase {
  func testSuccessfulMoves() async throws {
    for overwrites in [false, true] {
      let fixture = try makeFixture()
      if overwrites {
        try Data("destination".utf8).write(to: fixture.destination)
      }

      let result = await fixture.move(overwrites: overwrites)
      XCTAssertTrue(result)
      XCTAssertEqual(try fixture.contents(fixture.destination), "source")
      XCTAssertFalse(FileManager.default.fileExists(atPath: fixture.source.path))
    }
  }

  func testSameFileIsNoOp() async throws {
    let fixture = try makeFixture()
    let hardLink = fixture.root.appending(path: "hard-link")
    let symbolicLink = fixture.root.appending(path: "symbolic-link")

    let fileManager = FileManager.default
    try fileManager.linkItem(at: fixture.source, to: hardLink)
    try fileManager.createSymbolicLink(at: symbolicLink, withDestinationURL: fixture.source)

    for destination in [fixture.source, hardLink, symbolicLink] {
      for overwrites in [false, true] {
        let result = await fixture.move(to: destination, overwrites: overwrites)
        XCTAssertTrue(result)
        XCTAssertEqual(try fixture.contents(fixture.source), "source")
        XCTAssertEqual(try fixture.contents(destination), "source")
      }
    }

    XCTAssertEqual(
      try fileManager.destinationOfSymbolicLink(atPath: symbolicLink.path),
      fixture.source.path
    )
  }

  func testExistingDestinationRequiresOverwrite() async throws {
    let fixture = try makeFixture()
    try Data("destination".utf8).write(to: fixture.destination)
    for overwrites in [nil, false] as [Bool?] {
      let result = await fixture.move(overwrites: overwrites)
      XCTAssertFalse(result)
      XCTAssertEqual(try fixture.contents(fixture.source), "source")
      XCTAssertEqual(try fixture.contents(fixture.destination), "destination")
    }
  }

  func testMissingSourcePreservesDestination() async throws {
    let fixture = try makeFixture()
    try Data("destination".utf8).write(to: fixture.destination)
    try FileManager.default.removeItem(at: fixture.source)
    for destination in [fixture.source, fixture.destination] {
      let result = await fixture.move(to: destination, overwrites: true)
      XCTAssertFalse(result)
      XCTAssertEqual(try fixture.contents(fixture.destination), "destination")
    }
  }

  func testFailedRenamePreservesBothFiles() async throws {
    let fixture = try makeFixture()
    try Data("destination".utf8).write(to: fixture.destination)
    try FileManager.default.setAttributes([.immutable: true], ofItemAtPath: fixture.destination.path)
    addTeardownBlock {
      try FileManager.default.setAttributes([.immutable: false], ofItemAtPath: fixture.destination.path)
    }

    let result = await fixture.move(overwrites: true)
    XCTAssertFalse(result)
    XCTAssertEqual(try fixture.contents(fixture.source), "source")
    XCTAssertEqual(try fixture.contents(fixture.destination), "destination")
  }

  func testNonemptyDirectoryReplacementFailsWithoutChanges() async throws {
    let fixture = try makeFixture()
    let source = fixture.root.appending(path: "directory")
    try FileManager.default.createDirectory(at: source, withIntermediateDirectories: false)
    try FileManager.default.createDirectory(at: fixture.destination, withIntermediateDirectories: false)

    let child = fixture.destination.appending(path: "child")
    try Data("destination".utf8).write(to: child)
    let result = await fixture.move(from: source, overwrites: true)
    XCTAssertFalse(result)
    XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
    XCTAssertEqual(try fixture.contents(child), "destination")
  }

  func testCrossVolumeContract() async throws {
    guard let volume = ProcessInfo.processInfo.environment["MARKEDIT_TEST_VOLUME"] else {
      throw XCTSkip("Set TEST_RUNNER_MARKEDIT_TEST_VOLUME to a writable second volume for xcodebuild")
    }

    let fixture = try makeFixture()
    let other = try makeFixture(in: URL(filePath: volume))
    try Data("destination".utf8).write(to: other.source)
    let attributes = try FileManager.default.attributesOfItem(atPath: fixture.source.path)
    let otherAttributes = try FileManager.default.attributesOfItem(atPath: other.source.path)
    XCTAssertNotEqual(attributes[.systemNumber] as? NSNumber, otherAttributes[.systemNumber] as? NSNumber)

    let rejected = await fixture.move(to: other.source, overwrites: true)
    XCTAssertFalse(rejected)
    XCTAssertEqual(try fixture.contents(fixture.source), "source")
    XCTAssertEqual(try other.contents(other.source), "destination")

    let moved = await fixture.move(to: other.destination)
    XCTAssertTrue(moved)
    XCTAssertFalse(FileManager.default.fileExists(atPath: fixture.source.path))
    XCTAssertEqual(try other.contents(other.destination), "source")
  }
}

private extension MoveFileTests {
  func makeFixture(in directory: URL = FileManager.default.temporaryDirectory) throws -> Fixture {
    let root = directory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: false)
    addTeardownBlock {
      try FileManager.default.removeItem(at: root)
    }

    let fixture = Fixture(root: root)
    try Data("source".utf8).write(to: fixture.source)
    return fixture
  }

  @MainActor
  struct Fixture {
    let root: URL
    let delegate = Delegate()
    var source: URL { root.appending(path: "source") }
    var destination: URL { root.appending(path: "destination") }

    func move(from source: URL? = nil, to destination: URL? = nil, overwrites: Bool? = nil) async -> Bool {
      await EditorModuleAPI(delegate: delegate).moveFile(options: MoveFileOptions(
        source: (source ?? self.source).path,
        destination: (destination ?? self.destination).path,
        overwrites: overwrites
      ))
    }

    func contents(_ url: URL) throws -> String {
      try String(contentsOf: url, encoding: .utf8)
    }
  }

  @MainActor
  final class Delegate: EditorModuleAPIDelegate {
    func editorAPIGetFileURL(_ sender: EditorModuleAPI, path: String?) -> URL? {
      path.map { URL(filePath: $0) }
    }
    func editorAPISaveDocument(_ sender: EditorModuleAPI) async -> Bool { false }
    func editorAPICloseDocument(_ sender: EditorModuleAPI) -> Bool { false }
    func editorAPI(_ sender: EditorModuleAPI, addMainMenuItems items: [(String, WebMenuItem)]) {}
    func editorAPI(_ sender: EditorModuleAPI, showContextMenu items: [WebMenuItem], location: WebPoint) {}
    func editorAPI(
      _ sender: EditorModuleAPI, alertWith title: String?, message: String?, buttons: [String]?
    ) async -> Int { 0 }
    func editorAPI(
      _ sender: EditorModuleAPI, showTextBox title: String?, placeholder: String?, defaultValue: String?
    ) async -> String? { nil }
    func editorAPI(_ sender: EditorModuleAPI, showSavePanel data: Data, fileName: String?) async -> Bool { false }
    func editorAPI(_ sender: EditorModuleAPI, runService name: String, input: String?) async -> Bool { false }
    func editorAPIOpenFile(_ sender: EditorModuleAPI, fileURL: URL) -> Bool { false }
    func editorAPI(_ sender: EditorModuleAPI, restoreFileVersionContent content: String) async -> Bool { false }
    func editorAPITerminateApp(_ sender: EditorModuleAPI) {}
    func editorAPIRelaunchApp(_ sender: EditorModuleAPI) {}
  }
}
