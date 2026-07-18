//
//  ExtensionCoreTests.swift
//
//  Created by cyan on 7/12/26.
//

import XCTest
@testable import ExtensionCore

// swiftlint:disable:next type_body_length
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
      installDate: "2026-01-01T00:00:00Z"
    )

    let fresh = ExtensionConfig.Installed(
      id: "sample",
      version: "2.0.0",
      url: "https://example.com/new.js",
      sha256: "new",
      file: "sample.js",
      enabled: true,
      installDate: "2026-07-12T00:00:00Z"
    )

    let merged = fresh.merging(preserving: previous)
    // New download wins for version/url/sha256
    XCTAssertEqual(merged.version, "2.0.0")
    XCTAssertEqual(merged.url, "https://example.com/new.js")
    XCTAssertEqual(merged.sha256, "new")
    // Previous wins for the user-managed enabled flag and the original installDate
    XCTAssertEqual(merged.installDate, "2026-01-01T00:00:00Z")
    XCTAssertFalse(merged.enabled ?? true)
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

  // MARK: - ExtensionRelease.pageURL

  func testPageURLFromReleaseAsset() {
    let release = makeRelease(url: "https://github.com/owner/repo/releases/download/v1.0.0/ext.js")
    XCTAssertEqual(release.pageURL?.absoluteString, "https://github.com/owner/repo/releases/tag/v1.0.0")
  }

  func testPageURLFromRawContent() {
    let release = makeRelease(url: "https://raw.githubusercontent.com/owner/repo/v1.0.0/dist/ext.js")
    XCTAssertEqual(release.pageURL?.absoluteString, "https://github.com/owner/repo/tree/v1.0.0")
  }

  func testPageURLFromOfficialRawContentUsesReleasePage() {
    let release = makeRelease(url: "https://raw.githubusercontent.com/MarkEdit-app/MarkEdit-preview/v1.8.1/dist/ext.js")
    XCTAssertEqual(release.pageURL?.absoluteString, "https://github.com/MarkEdit-app/MarkEdit-preview/releases/tag/v1.8.1")
  }

  func testPageURLFromBlobRawLink() {
    let release = makeRelease(url: "https://github.com/owner/repo/blob/v1.0.0/dist/ext.js?raw=true")
    XCTAssertEqual(release.pageURL?.absoluteString, "https://github.com/owner/repo/tree/v1.0.0")
  }

  func testPageURLFromOfficialBlobRawLinkUsesReleasePage() {
    let release = makeRelease(url: "https://github.com/MarkEdit-app/MarkEdit-preview/blob/v1.8.1/dist/ext.js?raw=true")
    XCTAssertEqual(release.pageURL?.absoluteString, "https://github.com/MarkEdit-app/MarkEdit-preview/releases/tag/v1.8.1")
  }

  func testPageURLFallsBackToHost() {
    let release = makeRelease(url: "https://example.com/path/ext.js")
    XCTAssertEqual(release.pageURL?.absoluteString, "https://example.com")
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

  func testAvailableUpdatesAdoptsVersionlessOfficial() {
    ExtensionEnvironment.appVersion = "1.5.0"
    let index = makeIndex([makeEntry(id: "markedit-preview", version: "2.0.0")])
    // Version-less official scripts adopt the latest registry release
    let updates = ExtensionRegistry.availableUpdates(
      index: index,
      installed: [makeInstalled(id: "markedit-preview", version: nil)]
    )

    XCTAssertEqual(updates.count, 1)
    XCTAssertEqual(updates.first?.installed.id, "markedit-preview")
    XCTAssertEqual(updates.first?.entry.latest.version, "2.0.0")
  }

  func testAvailableUpdatesSkipsIncompatibleVersionlessOfficial() {
    ExtensionEnvironment.appVersion = "1.5.0"

    // An incompatible release is skipped before version-less adoption
    let index = makeIndex([makeEntry(id: "markedit-preview", version: "2.0.0", minAppVersion: "9.0.0")])
    let updates = ExtensionRegistry.availableUpdates(
      index: index,
      installed: [makeInstalled(id: "markedit-preview", version: nil)]
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

  // MARK: - hasCachedUpdates

  func testHasCachedUpdatesFalseWithoutCache() throws {
    let dir = try makeTempDir()
    defer {
      try? FileManager.default.removeItem(at: dir)
      ExtensionEnvironment.documentsDirectory = URL.documentsDirectory
      ExtensionEnvironment.cachesDirectory = URL.cachesDirectory
    }

    ExtensionEnvironment.documentsDirectory = dir
    ExtensionEnvironment.cachesDirectory = dir
    try seedInstalled([makeInstalled(id: "sample", version: "1.0.0")], in: dir)

    // No cached index on disk means there's nothing to compare against
    XCTAssertFalse(ExtensionRegistry.hasCachedUpdates)
  }

  func testHasCachedUpdatesReflectsCachedIndex() throws {
    let dir = try makeTempDir()
    let originalAppVersion = ExtensionEnvironment.appVersion
    defer {
      try? FileManager.default.removeItem(at: dir)
      ExtensionEnvironment.documentsDirectory = URL.documentsDirectory
      ExtensionEnvironment.cachesDirectory = URL.cachesDirectory
      ExtensionEnvironment.appVersion = originalAppVersion
    }

    ExtensionEnvironment.documentsDirectory = dir
    ExtensionEnvironment.cachesDirectory = dir
    ExtensionEnvironment.appVersion = "1.5.0"
    try seedInstalled([makeInstalled(id: "sample", version: "1.0.0")], in: dir)

    // A newer release in the cached index surfaces an update
    try seedCachedIndex(makeIndex([makeEntry(id: "sample", version: "2.0.0")]))
    XCTAssertTrue(ExtensionRegistry.hasCachedUpdates)

    // Only equal or older releases means nothing to update
    try seedCachedIndex(makeIndex([makeEntry(id: "sample", version: "1.0.0")]))
    XCTAssertFalse(ExtensionRegistry.hasCachedUpdates)
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

  // MARK: - setEnabled

  func testSetEnabledTogglesFlagInPlace() throws {
    let dir = try makeTempDir()
    defer {
      try? FileManager.default.removeItem(at: dir)
      ExtensionEnvironment.documentsDirectory = URL.documentsDirectory
    }

    ExtensionEnvironment.documentsDirectory = dir
    try seedExtensions(ids: ["a", "b", "c"], in: dir)

    // Absent flag means enabled
    XCTAssertNil(installedRecord(id: "b", in: dir)?["enabled"])

    ExtensionConfig.setEnabled(false, forID: "b")
    XCTAssertEqual(installedRecord(id: "b", in: dir)?["enabled"] as? Bool, false)

    // Order is preserved and siblings are untouched
    XCTAssertEqual(installedIds(in: dir), ["a", "b", "c"])
    XCTAssertNil(installedRecord(id: "a", in: dir)?["enabled"])

    ExtensionConfig.setEnabled(true, forID: "b")
    XCTAssertEqual(installedRecord(id: "b", in: dir)?["enabled"] as? Bool, true)
  }

  func testSetEnabledIgnoresUnknownIdentifier() throws {
    let dir = try makeTempDir()
    defer {
      try? FileManager.default.removeItem(at: dir)
      ExtensionEnvironment.documentsDirectory = URL.documentsDirectory
    }

    ExtensionEnvironment.documentsDirectory = dir
    try seedExtensions(ids: ["a"], in: dir)

    ExtensionConfig.setEnabled(false, forID: "missing")
    XCTAssertEqual(installedIds(in: dir), ["a"])
    XCTAssertNil(installedRecord(id: "a", in: dir)?["enabled"])
  }

  // MARK: - remove / uninstall

  func testRemoveDropsRecordOnly() throws {
    let dir = try makeTempDir()
    defer {
      try? FileManager.default.removeItem(at: dir)
      ExtensionEnvironment.documentsDirectory = URL.documentsDirectory
    }

    ExtensionEnvironment.documentsDirectory = dir
    try seedExtensions(ids: ["a", "b", "c"], in: dir)

    ExtensionConfig.remove(id: "b")
    XCTAssertEqual(installedIds(in: dir), ["a", "c"])

    // Removing an unknown id is a no-op
    ExtensionConfig.remove(id: "missing")
    XCTAssertEqual(installedIds(in: dir), ["a", "c"])
  }

  // MARK: - reorder

  func testReorderChangesInjectionOrder() throws {
    let dir = try makeTempDir()
    defer {
      try? FileManager.default.removeItem(at: dir)
      ExtensionEnvironment.documentsDirectory = URL.documentsDirectory
    }

    ExtensionEnvironment.documentsDirectory = dir
    try seedExtensions(ids: ["a", "b", "c"], in: dir)

    ExtensionConfig.reorder(orderedIDs: ["c", "a", "b"])
    XCTAssertEqual(installedIds(in: dir), ["c", "a", "b"])

    // Ids missing from the new order keep their relative position at the end
    ExtensionConfig.reorder(orderedIDs: ["b"])
    XCTAssertEqual(installedIds(in: dir), ["b", "c", "a"])
  }

  func testUninstallDeletesFileAndRecord() throws {
    let dir = try makeTempDir()
    defer {
      try? FileManager.default.removeItem(at: dir)
      ExtensionEnvironment.documentsDirectory = URL.documentsDirectory
    }

    ExtensionEnvironment.documentsDirectory = dir
    try seedExtensions(ids: ["a", "b"], in: dir)

    let scripts = dir.appending(path: "scripts", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: scripts, withIntermediateDirectories: true)
    let fileURL = scripts.appending(path: "b.js", directoryHint: .notDirectory)
    try Data("console.log('b')".utf8).write(to: fileURL)

    ExtensionDownloader.uninstall(makeInstalled(id: "b", version: "1.0.0"))
    XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
    XCTAssertEqual(installedIds(in: dir), ["a"])
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

  func makeRelease(url: String) -> ExtensionRelease {
    ExtensionRelease(
      version: "1.0.0",
      url: url,
      sha256: "abc",
      minAppVersion: nil,
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
      colorPatterns: nil,
      latest: makeRelease(version: version, minAppVersion: minAppVersion)
    )
  }

  func makeIndex(_ extensions: [ExtensionEntry]) -> ExtensionIndex {
    ExtensionIndex(schemaVersion: 1, extensions: extensions)
  }

  func makeInstalled(
    id: String,
    version: String?
  ) -> ExtensionConfig.Installed {
    ExtensionConfig.Installed(
      id: id,
      version: version,
      url: nil,
      sha256: nil,
      file: "\(id).js",
      enabled: nil,
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

  /// Writes extensions.json for records that carry a version, so update comparisons have something to compare.
  func seedInstalled(_ installed: [ExtensionConfig.Installed], in dir: URL) throws {
    let records = installed.map { item -> String in
      let version = item.version.map { "\"version\": \"\($0)\", " } ?? ""
      return "{ \(version)\"id\": \"\(item.id)\", \"file\": \"\(item.file)\" }"
    }

    let json = "{ \"installed\": [\n\(records.joined(separator: ",\n"))\n] }"
    try Data(json.utf8).write(to: dir.appending(path: "extensions.json", directoryHint: .notDirectory))
  }

  /// Writes a registry index to the on-disk cache location read by `cachedIndex`.
  func seedCachedIndex(_ index: ExtensionIndex) throws {
    let cacheDir = ExtensionEnvironment.indexCacheDirectory
    try FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)

    let data = try JSONEncoder().encode(index)
    try data.write(to: cacheDir.appending(path: "index.json", directoryHint: .notDirectory))
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

  func installedRecord(id: String, in dir: URL) -> [String: Any]? {
    let url = dir.appending(path: "extensions.json", directoryHint: .notDirectory)
    guard let data = try? Data(contentsOf: url),
          let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let installed = object["installed"] as? [[String: Any]] else {
      return nil
    }

    return installed.first { $0["id"] as? String == id }
  }
}
