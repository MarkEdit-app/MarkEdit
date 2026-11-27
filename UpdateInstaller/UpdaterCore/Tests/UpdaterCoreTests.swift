//
//  UpdaterCoreTests.swift
//
//  Created by cyan on 8/4/26.
//

import XCTest
@testable import UpdaterCore

final class UpdaterCoreTests: XCTestCase {
  private var root = URL(fileURLWithPath: NSTemporaryDirectory())

  override func setUpWithError() throws {
    root = URL(fileURLWithPath: NSTemporaryDirectory()).appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
  }

  override func tearDownWithError() throws {
    try FileManager.default.removeItem(at: root)
  }

  func testStagingDirectoryRejectsForeignPaths() {
    XCTAssertNil(StagingLocation.directory(of: "/Applications/MarkEdit.app"))
    XCTAssertNil(StagingLocation.directory(of: "/Applications"))
    XCTAssertNil(StagingLocation.directory(of: ""))
  }

  func testStagingDirectoryAcceptsOwnPaths() {
    let staging = "\(StagingLocation.prefix)AC5B3F7E"
    XCTAssertEqual(StagingLocation.directory(of: "/tmp/TemporaryItems/\(staging)/MarkEdit.app")?.lastPathComponent, staging)
    XCTAssertNil(StagingLocation.directory(of: "/tmp/TemporaryItems/\(staging)/MarkEdit.app/Contents"))
  }

  func testStagingDirectoryResolvesRelativeComponents() {
    let staging = "\(StagingLocation.prefix)AC5B3F7E"
    XCTAssertEqual(StagingLocation.directory(of: "/tmp/\(staging)/./MarkEdit.app")?.path, "/tmp/\(staging)")
    XCTAssertNil(StagingLocation.directory(of: "/tmp/\(staging)/../MarkEdit.app"))
  }

  func testHostBundleResolvesEmbeddedService() {
    let service = URL(fileURLWithPath: "/Applications/MarkEdit.app/Contents/XPCServices/UpdateInstaller.xpc")
    XCTAssertEqual(HostBundle.path(ofServiceAt: service), "/Applications/MarkEdit.app")
  }

  func testHostBundleRejectsUnexpectedLayouts() {
    let paths = [
      "/Applications/MarkEdit.app/Contents/XPCServices/UpdateInstaller",
      "/Applications/MarkEdit.app/Contents/MacOS/UpdateInstaller.xpc",
      "/Applications/MarkEdit.app/Contents/XPCServices/Nested/UpdateInstaller.xpc",
      "/Applications/MarkEdit/Contents/XPCServices/UpdateInstaller.xpc",
      "/tmp/UpdateInstaller.xpc",
    ]

    for path in paths {
      XCTAssertNil(HostBundle.path(ofServiceAt: URL(fileURLWithPath: path)), "Should reject \(path)")
    }
  }

  func testInstallerArgumentsRoundTrip() {
    for relaunch in [true, false] {
      let arguments = InstallerArguments(stagedPath: "/tmp/staged/MarkEdit.app", processIdentifier: 42, relaunch: relaunch)
      // argv[0] is the executable, exactly how the detached process sees it
      XCTAssertEqual(InstallerArguments(parsing: ["/path/to/UpdateInstaller"] + arguments.commandLine), arguments)
    }
  }

  func testInstallerArgumentsRejectIncompleteCommandLines() {
    let commandLines = [
      ["--install"],
      ["--install", "--staged", "/tmp/staged/MarkEdit.app"],
      ["--install", "--pid", "42"],
      ["--install", "--staged", "--pid", "42"],
      ["--install", "--staged", "/tmp/staged/MarkEdit.app", "--pid"],
      ["--install", "--staged", "/tmp/staged/MarkEdit.app", "--pid", "not-a-number"],
    ]

    for commandLine in commandLines {
      XCTAssertNil(InstallerArguments(parsing: commandLine), "Should reject \(commandLine)")
    }
  }

  func testIdentityAcceptsNewerVersions() throws {
    let candidate = try makeBundle(name: "New", version: "1.10.0")
    let reference = try makeBundle(name: "Old", version: "1.9.0")
    XCTAssertNoThrow(try BundleVerifier.checkIdentity(of: candidate, matching: reference))
  }

  func testIdentityRejectsSameOrOlderVersions() throws {
    let reference = try makeBundle(name: "Old", version: "1.9.0")

    for version in ["1.9.0", "1.8.9", "0.99.0"] {
      let candidate = try makeBundle(name: "New-\(version)", version: version)
      XCTAssertThrowsError(try BundleVerifier.checkIdentity(of: candidate, matching: reference)) { error in
        XCTAssertEqual(error as? BundleVerifier.Failure, .notNewer(version))
      }
    }
  }

  func testIdentityRejectsDifferentIdentifiers() throws {
    let candidate = try makeBundle(name: "Evil", version: "9.0.0", identifier: "app.cyan.evil")
    let reference = try makeBundle(name: "Old", version: "1.9.0")

    XCTAssertThrowsError(try BundleVerifier.checkIdentity(of: candidate, matching: reference)) { error in
      XCTAssertEqual(error as? BundleVerifier.Failure, .identifierMismatch)
    }
  }

  func testIdentityRejectsUnreadableBundles() throws {
    let reference = try makeBundle(name: "Old", version: "1.9.0")
    let missing = root.appending(path: "Missing.app").path(percentEncoded: false)

    // Bundles that can't be read must never pass as a match
    XCTAssertThrowsError(try BundleVerifier.checkIdentity(of: missing, matching: reference))
    XCTAssertThrowsError(try BundleVerifier.checkIdentity(of: reference, matching: missing))
    XCTAssertThrowsError(try BundleVerifier.checkIdentity(of: missing, matching: missing))
  }

  func testRequirementIsMissingForUnsignedBundles() throws {
    let bundle = try makeBundle(name: "Unsigned", version: "1.0.0")
    XCTAssertThrowsError(try BundleVerifier.designatedRequirement(of: bundle))
  }
}

// MARK: - Private

private extension UpdaterCoreTests {
  /// Creates an app bundle that only has the Info.plist keys the verifier reads.
  func makeBundle(name: String, version: String, identifier: String = "app.cyan.markedit") throws -> String {
    let bundle = root.appending(path: "\(name).app")
    let contents = bundle.appending(path: "Contents")
    try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)

    let info: [String: Any] = [
      "CFBundleIdentifier": identifier,
      "CFBundleShortVersionString": version,
      "CFBundlePackageType": "APPL",
    ]

    let data = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
    try data.write(to: contents.appending(path: "Info.plist"))

    return bundle.path(percentEncoded: false)
  }
}
