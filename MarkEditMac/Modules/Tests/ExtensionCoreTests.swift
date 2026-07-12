//
//  ExtensionCoreTests.swift
//
//  Created by cyan on 7/12/26.
//

import XCTest
@testable import ExtensionCore

final class ExtensionCoreTests: XCTestCase {

  // MARK: - identifier(fromFileName:)

  func testIdentifierFromFileName() {
    XCTAssertEqual(ExtensionConfig.identifier(fromFileName: "markedit-preview.js"), "markedit-preview")
    XCTAssertEqual(ExtensionConfig.identifier(fromFileName: "My_Cool Extension.js"), "my-cool-extension")
    XCTAssertEqual(ExtensionConfig.identifier(fromFileName: "Foo!!Bar.js"), "foo-bar")
  }

  func testIdentifierFallsBackWhenEmpty() {
    XCTAssertEqual(ExtensionConfig.identifier(fromFileName: "___.js"), "extension")
  }

  // MARK: - Installed

  func testInstalledAdoptingFileCapturesLocalFields() throws {
    let dir = try makeTempDir()
    defer { try? FileManager.default.removeItem(at: dir) }

    let fileURL = dir.appending(path: "MarkEdit-Preview.js", directoryHint: .notDirectory)
    try Data("console.log('hi')".utf8).write(to: fileURL)

    let installed = ExtensionConfig.Installed(adopting: fileURL)
    XCTAssertEqual(installed.id, "markedit-preview")
    XCTAssertEqual(installed.file, "MarkEdit-Preview.js")
    XCTAssertTrue(installed.enabled ?? false)
    XCTAssertEqual(installed.sha256?.count, 64)
    XCTAssertNotNil(installed.installDate)
    // Not derivable locally, filled later by the registry
    XCTAssertNil(installed.version)
    XCTAssertNil(installed.url)
  }

  func testMergingPreservesUserManagedFields() {
    let previous = ExtensionConfig.Installed(
      id: "sample",
      version: "1.0.0",
      url: "https://example.com/old.js",
      sha256: "old",
      file: "sample.js",
      enabled: false,
      updateCheck: .never,
      installDate: "2026-01-01T00:00:00Z"
    )

    let fresh = ExtensionConfig.Installed(
      id: "sample",
      version: "2.0.0",
      url: "https://example.com/new.js",
      sha256: "new",
      file: "sample.js",
      enabled: true,
      updateCheck: nil,
      installDate: "2026-07-12T00:00:00Z"
    )

    let merged = fresh.merging(preserving: previous)
    // New download wins for version/url/sha256
    XCTAssertEqual(merged.version, "2.0.0")
    XCTAssertEqual(merged.url, "https://example.com/new.js")
    XCTAssertEqual(merged.sha256, "new")
    // Previous wins for user-managed enabled/updateCheck and the original installDate
    XCTAssertEqual(merged.installDate, "2026-01-01T00:00:00Z")
    XCTAssertFalse(merged.enabled ?? true)
    XCTAssertEqual(merged.updateCheck, .never)
  }

  // MARK: - ExtensionRelease.isCompatible

  func testIsCompatibleAgainstAppVersion() {
    ExtensionEnvironment.appVersion = "1.5.0"
    XCTAssertTrue(makeRelease(version: "1", minAppVersion: nil).isCompatible)
    XCTAssertTrue(makeRelease(version: "1", minAppVersion: "").isCompatible)
    XCTAssertTrue(makeRelease(version: "1", minAppVersion: "1.4.0").isCompatible)
    XCTAssertTrue(makeRelease(version: "1", minAppVersion: "1.5.0").isCompatible)
    XCTAssertFalse(makeRelease(version: "1", minAppVersion: "1.6.0").isCompatible)
    XCTAssertFalse(makeRelease(version: "1", minAppVersion: "1.10.0").isCompatible)
  }

  // MARK: - availableUpdates

  func testAvailableUpdatesFindsNewerRelease() {
    ExtensionEnvironment.appVersion = "1.5.0"
    let index = makeIndex([makeEntry(id: "sample", version: "2.0.0")])
    let updates = ExtensionRegistry.availableUpdates(
      index: index,
      installed: [makeInstalled(id: "sample", version: "1.0.0")]
    )

    XCTAssertEqual(updates.count, 1)
    XCTAssertEqual(updates.first?.installed.id, "sample")
    XCTAssertEqual(updates.first?.entry.latest.version, "2.0.0")
  }

  func testAvailableUpdatesSkipsUntrackedNonOfficial() {
    let index = makeIndex([makeEntry(id: "sample", version: "2.0.0")])
    let updates = ExtensionRegistry.availableUpdates(
      index: index,
      installed: [makeInstalled(id: "sample", version: nil)]
    )

    XCTAssertTrue(updates.isEmpty)
  }

  func testAvailableUpdatesSkipsVersionlessOfficial() {
    ExtensionEnvironment.appVersion = "1.5.0"
    let index = makeIndex([makeEntry(id: "markedit-preview", version: "2.0.0")])
    // Version-less installs are not updates
    let updates = ExtensionRegistry.availableUpdates(
      index: index,
      installed: [makeInstalled(id: "markedit-preview", version: nil)]
    )

    XCTAssertTrue(updates.isEmpty)
  }

  func testAvailableUpdatesHonorsNeverFreeze() {
    let index = makeIndex([makeEntry(id: "sample", version: "2.0.0")])
    let updates = ExtensionRegistry.availableUpdates(
      index: index,
      installed: [makeInstalled(id: "sample", version: "1.0.0", updateCheck: .never)]
    )

    XCTAssertTrue(updates.isEmpty)
  }

  func testAvailableUpdatesSkipsIncompatibleRelease() {
    ExtensionEnvironment.appVersion = "1.5.0"
    let index = makeIndex([makeEntry(id: "sample", version: "2.0.0", minAppVersion: "9.0.0")])
    let updates = ExtensionRegistry.availableUpdates(
      index: index,
      installed: [makeInstalled(id: "sample", version: "1.0.0")]
    )

    XCTAssertTrue(updates.isEmpty)
  }

  func testAvailableUpdatesSkipsEqualOrOlder() {
    ExtensionEnvironment.appVersion = "1.5.0"
    let index = makeIndex([makeEntry(id: "sample", version: "1.0.0")])
    let updates = ExtensionRegistry.availableUpdates(
      index: index,
      installed: [makeInstalled(id: "sample", version: "1.0.0")]
    )

    XCTAssertTrue(updates.isEmpty)
  }

  func testAvailableUpdatesSkipsUnknownIdentifier() {
    ExtensionEnvironment.appVersion = "1.5.0"
    let index = makeIndex([makeEntry(id: "other", version: "2.0.0")])
    let updates = ExtensionRegistry.availableUpdates(
      index: index,
      installed: [makeInstalled(id: "sample", version: "1.0.0")]
    )

    XCTAssertTrue(updates.isEmpty)
  }

  // MARK: - ExtensionIndex.isSupported

  func testIndexSchemaVersionSupport() {
    XCTAssertTrue(ExtensionIndex(schemaVersion: ExtensionIndex.supportedSchemaVersion, extensions: []).isSupported)
    // Older schemas remain readable
    XCTAssertTrue(ExtensionIndex(schemaVersion: ExtensionIndex.supportedSchemaVersion - 1, extensions: []).isSupported)
    // A newer schema means the app is out of date
    XCTAssertFalse(ExtensionIndex(schemaVersion: ExtensionIndex.supportedSchemaVersion + 1, extensions: []).isSupported)
  }

  // MARK: - upsertInstalled

  func testUpsertUpdatesInPlaceAndAppendsNew() throws {
    let dir = try makeTempDir()
    defer {
      try? FileManager.default.removeItem(at: dir)
      ExtensionEnvironment.documentsDirectory = URL.documentsDirectory
    }

    ExtensionEnvironment.documentsDirectory = dir
    try seedExtensions(ids: ["a", "b", "c"], in: dir)

    // Updating an existing id keeps its injection position
    ExtensionConfig.upsertInstalled(makeInstalled(id: "b", version: "2.0.0"))
    XCTAssertEqual(installedIds(in: dir), ["a", "b", "c"])

    // A new id is appended
    ExtensionConfig.upsertInstalled(makeInstalled(id: "d", version: "1.0.0"))
    XCTAssertEqual(installedIds(in: dir), ["a", "b", "c", "d"])
  }
}

// MARK: - Private

private extension ExtensionCoreTests {
  func makeRelease(version: String, minAppVersion: String?) -> ExtensionRelease {
    ExtensionRelease(
      version: version,
      url: "https://example.com/sample.js",
      sha256: "abc",
      minAppVersion: minAppVersion,
      notes: nil
    )
  }

  func makeEntry(id: String, version: String, minAppVersion: String? = nil) -> ExtensionEntry {
    ExtensionEntry(
      id: id,
      name: id,
      description: "",
      author: "",
      homepage: "",
      category: .extension,
      colorScheme: nil,
      screenshots: nil,
      latest: makeRelease(version: version, minAppVersion: minAppVersion)
    )
  }

  func makeIndex(_ extensions: [ExtensionEntry]) -> ExtensionIndex {
    ExtensionIndex(schemaVersion: 1, extensions: extensions)
  }

  func makeInstalled(
    id: String,
    version: String?,
    updateCheck: ExtensionConfig.UpdateCheck? = nil
  ) -> ExtensionConfig.Installed {
    ExtensionConfig.Installed(
      id: id,
      version: version,
      url: nil,
      sha256: nil,
      file: "\(id).js",
      enabled: nil,
      updateCheck: updateCheck,
      installDate: nil
    )
  }

  func makeTempDir() throws -> URL {
    let dir = FileManager.default.temporaryDirectory
      .appending(path: "ExtensionCoreTests-\(UUID().uuidString)", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
  }

  func seedExtensions(ids: [String], in dir: URL) throws {
    let installed = ids.map { "{ \"id\": \"\($0)\", \"file\": \"\($0).js\" }" }.joined(separator: ",\n")
    let json = "{ \"installed\": [\n\(installed)\n] }"
    try Data(json.utf8).write(to: dir.appending(path: "extensions.json", directoryHint: .notDirectory))
  }

  func installedIds(in dir: URL) -> [String] {
    let url = dir.appending(path: "extensions.json", directoryHint: .notDirectory)
    guard let data = try? Data(contentsOf: url),
          let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let installed = object["installed"] as? [[String: Any]] else {
      return []
    }

    return installed.compactMap { $0["id"] as? String }
  }
}
