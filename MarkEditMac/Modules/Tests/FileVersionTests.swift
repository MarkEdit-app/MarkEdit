//
//  FileVersionTests.swift
//
//  Created by cyan on 8/25/26.
//

import MarkEditKit
import XCTest

final class FileVersionTests: XCTestCase {
  func testFetchLocalContentsReturnsImmediatelyForLocalVersion() async throws {
    let fixture = try makeFixture(count: 1)
    defer { fixture.remove() }

    let version = try XCTUnwrap(fixture.versions.first)
    XCTAssertFalse(version.needsDownloading)

    let succeeded = await version.fetchLocalContents()
    XCTAssertTrue(succeeded)
  }

  func testNewestToOldestWithoutThrottlingPreservesAllVersions() throws {
    let fixture = try makeFixture(count: 3)
    defer { fixture.remove() }

    let sorted = fixture.versions.reversed().newestToOldest(throttle: false)
    XCTAssertEqual(sorted.count, fixture.versions.count)
    XCTAssertEqual(sorted.map(\.modificationDate), sorted.map(\.modificationDate).sorted {
      ($0 ?? .distantPast) > ($1 ?? .distantPast)
    })
  }

  func testNewestToOldestKeepsOneVersionPerSecond() throws {
    let fixture = try makeFixture(count: 5)
    defer { fixture.remove() }

    let sorted = fixture.versions.newestToOldest()
    let seconds = fixture.versions.map {
      Int(($0.modificationDate ?? .distantPast).timeIntervalSinceReferenceDate)
    }

    XCTAssertEqual(sorted.count, Set(seconds).count)
  }

  @MainActor
  func testEditorModuleAPIPreservesVersionIDs() async throws {
    let fixture = try makeFixture(count: 3)
    defer { fixture.remove() }

    let delegate = EditorModuleAPIDelegateStub(fileURL: fixture.documentURL)
    let api = EditorModuleAPI(delegate: delegate)
    let first = try decodeVersions(await api.getFileVersions())
    let second = try decodeVersions(await api.getFileVersions())
    XCTAssertEqual(Set(first.map(\.id)), Set(second.map(\.id)))
  }

  @MainActor
  func testEditorModuleAPIRestoresVersionContent() async throws {
    let fixture = try makeFixture(count: 1)
    defer { fixture.remove() }

    let delegate = EditorModuleAPIDelegateStub(fileURL: fixture.documentURL)
    let api = EditorModuleAPI(delegate: delegate)
    let versions = try decodeVersions(await api.getFileVersions())
    let version = try XCTUnwrap(versions.first)
    let content = await api.getFileVersionContent(id: version.id)
    let restored = await api.restoreFileVersion(id: version.id)

    XCTAssertTrue(restored)
    XCTAssertEqual(delegate.restoredContent, content)
  }

  @MainActor
  func testEditorModuleAPIDeletesFileVersions() async throws {
    let fixture = try makeFixture(count: 2)
    defer { fixture.remove() }

    let delegate = EditorModuleAPIDelegateStub(fileURL: fixture.documentURL)
    let api = EditorModuleAPI(delegate: delegate)
    let versions = try decodeVersions(await api.getFileVersions())
    let deleted = await api.deleteFileVersions(ids: versions.map(\.id))
    let remaining = try decodeVersions(await api.getFileVersions())

    XCTAssertTrue(deleted)
    XCTAssertTrue(remaining.isEmpty)
  }

  @MainActor
  func testEditorModuleAPIRejectsInvalidVersionIDsWithoutDeleting() async throws {
    let fixture = try makeFixture(count: 2)
    defer { fixture.remove() }

    let delegate = EditorModuleAPIDelegateStub(fileURL: fixture.documentURL)
    let api = EditorModuleAPI(delegate: delegate)
    let versions = try decodeVersions(await api.getFileVersions())
    let deleted = await api.deleteFileVersions(ids: [versions[0].id, "invalid"])
    let remaining = try decodeVersions(await api.getFileVersions())

    XCTAssertFalse(deleted)
    XCTAssertEqual(Set(remaining.map(\.id)), Set(versions.map(\.id)))
  }

  @MainActor
  func testEditorModuleAPIInvalidatesIDsAfterDocumentChange() async throws {
    let fixture = try makeFixture(count: 1)
    defer { fixture.remove() }

    let delegate = EditorModuleAPIDelegateStub(fileURL: fixture.documentURL)
    let api = EditorModuleAPI(delegate: delegate)
    let versions = try decodeVersions(await api.getFileVersions())
    let version = try XCTUnwrap(versions.first)
    delegate.fileURL = fixture.directory.appending(path: "other.md", directoryHint: .notDirectory)
    let content = await api.getFileVersionContent(id: version.id)
    XCTAssertNil(content)
  }
}

// MARK: - Private

private extension FileVersionTests {
  struct Fixture {
    let directory: URL
    let documentURL: URL
    let versions: [NSFileVersion]

    func remove() {
      versions.forEach { try? $0.remove() }
      try? FileManager.default.removeItem(at: directory)
    }
  }

  func makeFixture(count: Int) throws -> Fixture {
    let directory = FileManager.default.temporaryDirectory
      .appending(path: UUID().uuidString, directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    let documentURL = directory.appending(path: "document.md", directoryHint: .notDirectory)
    try Data("current".utf8).write(to: documentURL)

    let versions = try (0..<count).map { index in
      let contentsURL = directory.appending(path: "version-\(index).md", directoryHint: .notDirectory)
      try Data("version \(index)".utf8).write(to: contentsURL)
      return try NSFileVersion.addOfItem(
        at: documentURL,
        withContentsOf: contentsURL,
        options: []
      )
    }

    return Fixture(directory: directory, documentURL: documentURL, versions: versions)
  }

  func decodeVersions(_ json: String?) throws -> [FileVersionInfo] {
    let data = try XCTUnwrap(json?.data(using: .utf8))
    return try JSONDecoder().decode([FileVersionInfo].self, from: data)
  }
}

private struct FileVersionInfo: Decodable {
  let id: String
}

@MainActor
private final class EditorModuleAPIDelegateStub: EditorModuleAPIDelegate {
  var fileURL: URL?
  var restoredContent: String?

  init(fileURL: URL?) {
    self.fileURL = fileURL
  }

  func editorAPISaveDocument(_ sender: EditorModuleAPI) async -> Bool { true }
  func editorAPICloseDocument(_ sender: EditorModuleAPI) -> Bool { true }
  func editorAPI(_ sender: EditorModuleAPI, addMainMenuItems items: [(String, WebMenuItem)]) {}
  func editorAPI(_ sender: EditorModuleAPI, showContextMenu items: [WebMenuItem], location: WebPoint) {}
  func editorAPI(
    _ sender: EditorModuleAPI,
    alertWith title: String?,
    message: String?,
    buttons: [String]?
  ) async -> Int { 0 }
  func editorAPI(
    _ sender: EditorModuleAPI,
    showTextBox title: String?,
    placeholder: String?,
    defaultValue: String?
  ) async -> String? { nil }
  func editorAPI(_ sender: EditorModuleAPI, showSavePanel data: Data, fileName: String?) async -> Bool { false }
  func editorAPI(_ sender: EditorModuleAPI, runService name: String, input: String?) async -> Bool { false }
  func editorAPIOpenFile(_ sender: EditorModuleAPI, fileURL: URL) -> Bool { false }
  func editorAPIGetFileURL(_ sender: EditorModuleAPI, path: String?) -> URL? { fileURL }

  func editorAPI(_ sender: EditorModuleAPI, restoreFileVersionContent content: String) async -> Bool {
    restoredContent = content
    return true
  }

  func editorAPITerminateApp(_ sender: EditorModuleAPI) {}
  func editorAPIRelaunchApp(_ sender: EditorModuleAPI) {}
}
