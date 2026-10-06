import AppKit
import ExtensionCore
import MarkEditKit
import PDFKit
import XCTest
@testable import MarkEdit

@MainActor
final class EditorDocumentTests: XCTestCase {
  override static func setUp() {
    super.setUp()
    precondition(ApplicationEnvironment.isRunningTests, "Hosted tests must bypass normal application startup")
    XCTAssertTrue(NSApp.windows.isEmpty)
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
  }

  func testHostDoesNotRecordRecentDocuments() throws {
    let controller = try XCTUnwrap(NSDocumentController.shared as? AppDocumentController)
    let originalURLs = controller.recentDocumentURLs
    let url = ApplicationEnvironment.documentsDirectory.appending(path: "recent.md")
    try Data("Test document".utf8).write(to: url)

    controller.noteNewRecentDocumentURL(url)
    XCTAssertEqual(controller.recentDocumentURLs, originalURLs)
  }

  func testRecentDocumentPathsMatchesDocumentController() async throws {
    let editor = EditorViewController(preloadDelay: 60)
    let api = EditorModuleAPI(delegate: editor)
    let expected = NSDocumentController.shared.recentDocumentURLs.map(\.path)

    let paths = await api.recentDocumentPaths()
    XCTAssertEqual(paths, expected)

    let result = await api.bridge.invoke(method: "recentDocumentPaths", parameters: Data("{}".utf8))
    let value = try XCTUnwrap(result).get()
    XCTAssertEqual(try XCTUnwrap(value as? [String]), expected)
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
}

extension EditorDocumentTests {
  func testScriptLoadingBindsInstalledIdentityAndFiltersDisabledScripts() throws {
    AppCustomization.createFiles()
    let id = "script-loading-test"
    let scriptURL = AppCustomization.scriptsDirectory.fileURL.appending(path: "\(id).js")
    try Data("window.testScript = true;".utf8).write(to: scriptURL)

    defer {
      ExtensionConfig.remove(id: id)
      do {
        try FileManager.default.removeItem(at: scriptURL)
      } catch {
        XCTFail("Unable to remove test script: \(error)")
      }
    }

    ExtensionConfig.upsertInstalled(ExtensionConfig.Installed(
      id: id,
      version: "1",
      url: nil,
      sha256: nil,
      file: scriptURL.lastPathComponent,
      enabled: true,
      installDate: nil
    ))

    let first = try XCTUnwrap(AppCustomization.userScripts().first { $0.id == id })
    let second = try XCTUnwrap(AppCustomization.userScripts().first { $0.id == id })
    XCTAssertEqual(first.path, scriptURL.resolvingSymlinksInPath().path)
    XCTAssertEqual(first.id, second.id)
    XCTAssertEqual(first.path, second.path)
    XCTAssertTrue(first.source.contains(first.path))
    XCTAssertTrue(first.source.contains("window.testScript = true;"))

    ExtensionConfig.setEnabled(false, forID: id)
    XCTAssertFalse(AppCustomization.userScripts().contains { $0.id == id })
  }

  func testClosingDocumentCancelsDeferredWindowPresentation() async throws {
    let storyboard = NSStoryboard(name: "Main", bundle: nil)
    var controller: EditorWindowController? = try XCTUnwrap(
      storyboard.instantiateController(withIdentifier: "EditorWindowController") as? EditorWindowController
    )

    var editor: EditorViewController? = EditorViewController(preloadDelay: 60)
    editor?.view = NSView()
    editor?.hasFinishedLoading = true
    editor?.pendingResetCount = 1
    controller?.contentViewController = editor
    weak let releasedController = controller
    weak let releasedEditor = editor

    let window = try XCTUnwrap(controller?.window)
    defer { window.close() }

    let document = NSDocument()
    document.addWindowController(try XCTUnwrap(controller))
    controller?.showWindow(nil)
    document.close()
    XCTAssertNil(controller?.document)

    await editor?.waitUntilEditorReset()
    controller?.contentViewController = nil
    controller = nil
    editor = nil

    let deadline = ContinuousClock.now + .seconds(5)
    while releasedController != nil || releasedEditor != nil, ContinuousClock.now < deadline {
      try await Task.sleep(for: .milliseconds(10))
    }
    XCTAssertNil(releasedController)
    XCTAssertNil(releasedEditor)
    XCTAssertFalse(window.isVisible)
  }

  func testPrintWithoutWindow() async throws {
    let document = EditorDocument()
    let data = Data("Windowless printing\n".utf8)
    try document.read(from: data, ofType: "public.plain-text")
    XCTAssertTrue(document.windowControllers.isEmpty)

    defer {
      document.isTerminating = true
      document.close()
    }

    let url = ApplicationEnvironment.documentsDirectory.appending(path: "\(UUID().uuidString).pdf")
    defer { try? FileManager.default.removeItem(at: url) }

    let originalInfo = try XCTUnwrap(document.printInfo.dictionary().copy() as? NSDictionary)
    let completed = expectation(description: "Printing completes")
    let context = UnsafeMutableRawPointer.allocate(byteCount: 1, alignment: 1)
    defer { context.deallocate() }

    let delegate = PrintDelegate { printedDocument, success, returnedContext in
      XCTAssertIdentical(printedDocument, document)
      XCTAssertTrue(success)
      XCTAssertEqual(returnedContext, context)
      completed.fulfill()
    }

    document.print(
      withSettings: [
        .jobDisposition: NSPrintInfo.JobDisposition.save,
        .jobSavingURL: url,
        .paperSize: NSSize(width: 400, height: 600),
      ],
      showPrintPanel: false,
      delegate: delegate,
      didPrint: #selector(PrintDelegate.document(_:didPrint:contextInfo:)),
      contextInfo: context
    )

    await fulfillment(of: [completed], timeout: 10)
    withExtendedLifetime(delegate) {}
    XCTAssertEqual(document.fileData, data)
    XCTAssertEqual(document.printInfo.dictionary(), originalInfo)

    let pdf = try XCTUnwrap(PDFDocument(url: url))
    XCTAssertEqual(pdf.pageCount, 1)
    XCTAssertTrue(try XCTUnwrap(pdf.string).contains("Windowless printing"))
    XCTAssertEqual(pdf.page(at: 0)?.bounds(for: .mediaBox).size, NSSize(width: 400, height: 600))
  }
}

extension EditorDocumentTests {
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

  @MainActor
  private final class PrintDelegate: NSObject {
    let completion: (NSDocument, Bool, UnsafeMutableRawPointer?) -> Void

    init(completion: @escaping (NSDocument, Bool, UnsafeMutableRawPointer?) -> Void) {
      self.completion = completion
    }

    @objc func document(_ document: NSDocument, didPrint success: Bool, contextInfo: UnsafeMutableRawPointer?) {
      completion(document, success, contextInfo)
    }
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
