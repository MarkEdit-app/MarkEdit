import AppKit
import XCTest
@testable import MarkEdit

@MainActor
final class EditorDocumentTests: XCTestCase {
  override static func setUp() {
    super.setUp()
    precondition(ApplicationEnvironment.isRunningTests, "Hosted tests must bypass normal application startup")
  }

  override static func tearDown() {
    ApplicationEnvironment.preferences.removePersistentDomain(
      forName: ApplicationEnvironment.testIdentifier
    )

    do {
      try FileManager.default.removeItem(at: ApplicationEnvironment.documentsDirectory)
    } catch {
      XCTFail("Unable to remove test customization directory: \(error)")
    }

    super.tearDown()
  }

  func testHostSkipsApplicationLifecycle() async throws {
    let delegate = try XCTUnwrap(NSApp.delegate as? AppDelegate)
    XCTAssertTrue(UserDefaults.standard.bool(forKey: "ApplePersistenceIgnoreState"))
    XCTAssertNotIdentical(ApplicationEnvironment.preferences, UserDefaults.standard)
    XCTAssertNotEqual(ApplicationEnvironment.documentsDirectory, URL.documentsDirectory)
    XCTAssertEqual(
      AppCustomization.settings.fileURL.deletingLastPathComponent(),
      ApplicationEnvironment.documentsDirectory.resolvingSymlinksInPath()
    )

    XCTAssertEqual(AppPreferences.General.defaultTextEncoding, .utf8)
    XCTAssertEqual(AppPreferences.General.newFilenameExtension, .md)

    let stagedPath = ApplicationEnvironment.documentsDirectory.appending(path: "staged-update").path
    AppPreferences.Updater.stagedUpdatePath = stagedPath
    AppPreferences.Updater.stagedUpdateVersion = "test-version"
    defer {
      AppPreferences.Updater.stagedUpdatePath = nil
      AppPreferences.Updater.stagedUpdateVersion = nil
    }

    // Normal startup schedules updater maintenance after two seconds.
    try await Task.sleep(for: .seconds(2.2))
    XCTAssertEqual(delegate.applicationShouldTerminate(NSApp), .terminateNow)
    delegate.applicationWillTerminate(Notification(name: NSApplication.willTerminateNotification, object: NSApp))
    XCTAssertEqual(AppPreferences.Updater.stagedUpdatePath, stagedPath)
    XCTAssertEqual(AppPreferences.Updater.stagedUpdateVersion, "test-version")
    XCTAssertTrue(NSApp.windows.isEmpty)
  }

  func testHostDoesNotRecordRecentDocuments() throws {
    let controller = try XCTUnwrap(NSDocumentController.shared as? AppDocumentController)
    let originalURLs = controller.recentDocumentURLs
    let url = ApplicationEnvironment.documentsDirectory.appending(path: "recent.md")
    try Data("Test document".utf8).write(to: url)

    controller.noteNewRecentDocumentURL(url)
    XCTAssertEqual(controller.recentDocumentURLs, originalURLs)
  }

  func testPreferenceWritesUseIsolatedSuite() throws {
    let key = "test-isolation.\(UUID().uuidString)"
    let preferences = ApplicationEnvironment.preferences
    var storage = Storage(key: key, defaultValue: "")
    storage.wrappedValue = "test-value"

    XCTAssertEqual(storage.wrappedValue, "test-value")
    XCTAssertNotNil(preferences.object(forKey: key))
    XCTAssertNotNil(ApplicationEnvironment.preferences.object(forKey: key))
    XCTAssertNil(UserDefaults.standard.object(forKey: key))

    preferences.removeObject(forKey: key)
    XCTAssertEqual(storage.wrappedValue, "")
    XCTAssertNil(ApplicationEnvironment.preferences.object(forKey: key))
  }

  func testReadLoadsTextAndData() async throws {
    let document = EditorDocument()
    let data = Data("Document text\n".utf8)
    try document.read(from: data, ofType: "public.plain-text")

    try await Self.waitUntilLoaded(document, data: data)
    XCTAssertEqual(document.stringValue, "Document text\n")
  }

  func testReadReplacesLoadedText() async throws {
    let document = EditorDocument()
    let original = Data("Original text\n".utf8)
    try document.read(from: original, ofType: "public.plain-text")
    try await Self.waitUntilLoaded(document, data: original)

    let replacement = Data("Replacement text\n".utf8)
    try document.read(from: replacement, ofType: "public.plain-text")
    try await Self.waitUntilLoaded(document, data: replacement)
    XCTAssertEqual(document.stringValue, "Replacement text\n")
  }

  func testTextBundleRoundTrip() async throws {
    let document = EditorDocument()
    let directory = ApplicationEnvironment.documentsDirectory.appending(path: UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }

    let data = Data("Bundle text\n".utf8)
    let wrapper = Self.textBundle(contents: data)
    try document.read(from: wrapper, ofType: "org.textbundle.package")
    try await Self.waitUntilLoaded(document, data: data)
    try document.write(to: directory, ofType: "org.textbundle.package")

    XCTAssertEqual(document.stringValue, "Bundle text\n")
    XCTAssertEqual(try Data(contentsOf: directory.appending(path: "assets/image.png")), Data([1, 2, 3]))
    XCTAssertEqual(
      try Data(contentsOf: directory.appending(path: "text.markdown")),
      try document.data(ofType: "org.textbundle.package")
    )

    XCTAssertTrue(document.writableTypes(for: .saveOperation).contains("org.textbundle.package"))
  }

  func testConcurrentOpeningThroughAppKit() async throws {
    let directory = ApplicationEnvironment.documentsDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let controller = NSDocumentController.shared
    try await withThrowingTaskGroup(of: Void.self) { group in
      for index in 0..<4 {
        let url = directory.appending(path: "\(index).md")
        let text = "Concurrent document \(index)\n"
        try Data(text.utf8).write(to: url)

        group.addTask {
          try await Self.openAndVerify(controller: controller, url: url, text: text)
        }
      }

      try await group.waitForAll()
    }
  }

  func testAsynchronousSaveThroughAppKit() async throws {
    let directory = ApplicationEnvironment.documentsDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let url = directory.appending(path: "saved.md")
    let controller = NSDocumentController.shared
    let document = try EditorDocument(type: "app.markedit.md")
    controller.addDocument(document)
    document.stringValue = "Asynchronous save\n"
    defer {
      document.isTerminating = true
      document.close()
      controller.removeDocument(document)
    }

    XCTAssertTrue(document.canAsynchronouslyWrite(to: url, ofType: "app.markedit.md", for: .saveAsOperation))
    try await document.save(to: url, ofType: "app.markedit.md", for: .saveAsOperation)

    XCTAssertEqual(try Data(contentsOf: url), try document.data(ofType: "app.markedit.md"))
    XCTAssertEqual(document.fileURL, url)
  }

  func testAsynchronousTextBundleSaveThroughAppKit() async throws {
    let directory = ApplicationEnvironment.documentsDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let url = directory.appending(path: "saved.textbundle")
    let controller = NSDocumentController.shared
    let document = try EditorDocument(type: "org.textbundle.package")
    controller.addDocument(document)
    defer {
      document.isTerminating = true
      document.close()
      controller.removeDocument(document)
    }

    let data = Data("Original text\n".utf8)
    try document.read(from: Self.textBundle(contents: data), ofType: "org.textbundle.package")
    try await Self.waitUntilLoaded(document, data: data)
    document.stringValue = "Updated bundle\n"

    XCTAssertTrue(document.canAsynchronouslyWrite(to: url, ofType: "org.textbundle.package", for: .saveAsOperation))
    try await document.save(to: url, ofType: "org.textbundle.package", for: .saveAsOperation)

    XCTAssertEqual(
      try Data(contentsOf: url.appending(path: "text.markdown")),
      try document.data(ofType: "org.textbundle.package")
    )

    XCTAssertEqual(try Data(contentsOf: url.appending(path: "assets/image.png")), Data([1, 2, 3]))
    XCTAssertEqual(document.fileURL, url)
  }

  private static func openAndVerify(controller: NSDocumentController, url: URL, text: String) async throws {
    let (openedDocument, _) = try await controller.openDocument(withContentsOf: url, display: false)
    let document = try XCTUnwrap(openedDocument as? EditorDocument)
    defer {
      document.isTerminating = true
      document.close()
      controller.removeDocument(document)
    }

    try await waitUntilLoaded(document, data: Data(text.utf8))
    XCTAssertEqual(document.stringValue, text)
    XCTAssertEqual(document.fileURL, url)
  }

  private static func waitUntilLoaded(_ document: EditorDocument, data: Data) async throws {
    let deadline = ContinuousClock.now + .seconds(5)
    while document.fileData != data, ContinuousClock.now < deadline {
      try await Task.sleep(for: .milliseconds(10))
    }

    XCTAssertEqual(document.fileData, data)
  }

  private static func textBundle(contents: Data) -> FileWrapper {
    FileWrapper(directoryWithFileWrappers: [
      "info.json": FileWrapper(regularFileWithContents: Data(#"{"version":2,"type":"net.daringfireball.markdown"}"#.utf8)),
      "text.markdown": FileWrapper(regularFileWithContents: contents),
      "assets": FileWrapper(directoryWithFileWrappers: [
        "image.png": FileWrapper(regularFileWithContents: Data([1, 2, 3])),
      ]),
    ])
  }
}
