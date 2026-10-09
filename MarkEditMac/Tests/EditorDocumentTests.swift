import AppKit
import AppKitExtensions
import ExtensionCore
import MarkEditCore
import MarkEditKit
import PDFKit
import Security
import WebKit
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

  func testOpenDocumentAPI() async throws {
    let directory = ApplicationEnvironment.documentsDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let editor = EditorViewController(preloadDelay: 60)
    let api = EditorModuleAPI(delegate: editor)
    let controller = NSDocumentController.shared

    let url = directory.appending(path: "document.txt")
    let data = Data("Plain text\n".utf8)
    try data.write(to: url)

    let parameters = try JSONSerialization.data(withJSONObject: ["path": url.path])
    let result = await api.bridge.invoke(method: "openDocument", parameters: parameters)
    XCTAssertEqual(try XCTUnwrap(result).get() as? Bool, true)

    let document = try XCTUnwrap(controller.document(for: url) as? EditorDocument)
    defer {
      document.isTerminating = true
      document.close()
      controller.removeDocument(document)
    }

    try await Self.waitUntilLoaded(document, data: data)
    XCTAssertEqual(document.stringValue, "Plain text\n")

    let reopened = await api.openDocument(path: url.path, target: .window)
    XCTAssertTrue(reopened)
    XCTAssertIdentical(controller.document(for: url), document)
  }

  func testOpenDocumentAPIFollowsSymlink() async throws {
    let directory = ApplicationEnvironment.documentsDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let url = directory.appending(path: "document.txt")
    let link = directory.appending(path: "link.txt")
    let data = Data("Plain text\n".utf8)
    try data.write(to: url)
    try FileManager.default.createSymbolicLink(at: link, withDestinationURL: url)

    let editor = EditorViewController(preloadDelay: 60)
    let api = EditorModuleAPI(delegate: editor)
    let opened = await api.openDocument(path: link.path, target: nil)
    XCTAssertTrue(opened)

    let controller = NSDocumentController.shared
    let document = try XCTUnwrap(controller.document(for: url) as? EditorDocument)
    defer {
      document.isTerminating = true
      document.close()
      controller.removeDocument(document)
    }

    try await Self.waitUntilLoaded(document, data: data)
    XCTAssertEqual(document.stringValue, "Plain text\n")

    let reopened = await api.openDocument(path: link.path, target: .window)
    XCTAssertTrue(reopened)
    XCTAssertIdentical(controller.document(for: url), document)
  }

  func testOpenDocumentAPIRejectsUnsupportedFiles() async throws {
    let directory = ApplicationEnvironment.documentsDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let editor = EditorViewController(preloadDelay: 60)
    let api = EditorModuleAPI(delegate: editor)
    let controller = NSDocumentController.shared
    let originalCount = controller.documents.count

    let binary = directory.appending(path: "image.png")
    try Data([0, 1, 2]).write(to: binary)
    let link = directory.appending(path: "image.txt")
    try FileManager.default.createSymbolicLink(at: link, withDestinationURL: binary)

    for url in [binary, link, directory, directory.appending(path: "missing.md")] {
      let opened = await api.openDocument(path: url.path, target: .tab)
      XCTAssertFalse(opened)
    }

    XCTAssertEqual(controller.documents.count, originalCount)
  }

  func testOpenDocumentWindowTargets() async throws {
    let storyboard = NSStoryboard(name: "Main", bundle: nil)
    let source = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
      styleMask: [.titled, .closable, .resizable],
      backing: .buffered,
      defer: false
    )

    source.isReleasedWhenClosed = false
    source.tabbingMode = .disallowed
    source.makeKeyAndOrderFront(nil)
    defer { source.close() }

    let other = NSWindow(contentRect: source.frame, styleMask: source.styleMask, backing: .buffered, defer: false)
    other.isReleasedWhenClosed = false
    other.tabbingMode = .disallowed
    other.makeKeyAndOrderFront(nil)
    defer { other.close() }

    let allowsTabbing = NSWindow.allowsAutomaticWindowTabbing
    defer { NSWindow.allowsAutomaticWindowTabbing = allowsTabbing }
    NSWindow.allowsAutomaticWindowTabbing = true

    let cases: [(OpenDocumentTarget, NSWindow.TabbingMode, NSWindow?)] = [
      (.window, .preferred, source),
      (.tab, .disallowed, source),
      (.tab, .preferred, nil),
      (.automatic, .disallowed, source),
    ]

    for (target, tabbingMode, host) in cases {
      source.tabbingMode = tabbingMode
      other.tabbingMode = tabbingMode
      other.makeKeyAndOrderFront(nil)

      let controller = try XCTUnwrap(
        storyboard.instantiateController(withIdentifier: "EditorWindowController") as? EditorWindowController
      )

      let window = try XCTUnwrap(controller.window)
      window.tabbingIdentifier = source.tabbingIdentifier
      window.tabbingMode = tabbingMode

      let document = NSDocument()
      document.addWindowController(controller)
      defer {
        document.close()
        window.close()
      }

      try await controller.showWindow(target: target, relativeTo: host)
      XCTAssertTrue(window.isVisible)
      XCTAssertEqual(source.tabbedWindows?.contains(window) == true, target == .tab && host != nil)
      XCTAssertNotEqual(other.tabbedWindows?.contains(window), true)

      if target == .tab, host != nil {
        XCTAssertIdentical(source.tabGroup?.selectedWindow, window)
      }

      XCTAssertTrue(NSWindow.allowsAutomaticWindowTabbing)
      XCTAssertEqual(window.tabbingMode, tabbingMode)
    }
  }

  func testOpenDocumentClosedBeforePresentationFails() async throws {
    let storyboard = NSStoryboard(name: "Main", bundle: nil)
    let controller = try XCTUnwrap(
      storyboard.instantiateController(withIdentifier: "EditorWindowController") as? EditorWindowController
    )

    let window = try XCTUnwrap(controller.window)
    let document = NSDocument()
    document.addWindowController(controller)

    defer { window.close() }
    document.close()

    do {
      try await controller.showWindow(target: .window, relativeTo: nil)
      XCTFail("A closed document must not be presented")
    } catch is CancellationError {
      XCTAssertFalse(window.isVisible)
    }
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
  func testSecretStorageResistsPromiseHooksInWebKit() async throws {
    AppCustomization.createFiles()
    let completed = expectation(description: "Protected reads complete")
    let victim = EditorModuleSecretStorage.Context(id: "victim", path: "/victim.js")
    let probe = SecretReplyProbe(capability: victim.capability, completed: completed)
    let configuration = WKWebViewConfiguration()
    let controller = configuration.userContentController
    controller.addScriptMessageHandler(probe, contentWorld: .page, name: "bridge")
    controller.addScriptMessageHandler(probe, contentWorld: .page, name: "testResults")
    defer { controller.removeAllScriptMessageHandlers() }

    let attacker = """
    const constructor = Object.getOwnPropertyDescriptor(Promise.prototype, 'constructor');
    const then = Object.getOwnPropertyDescriptor(Promise.prototype, 'then');
    const species = Object.getOwnPropertyDescriptor(Promise, Symbol.species);
    window.intercepted = [];
    window.restorePromiseHooks = () => {
      Object.defineProperty(Promise.prototype, 'constructor', constructor);
      Object.defineProperty(Promise.prototype, 'then', then);
      Object.defineProperty(Promise, Symbol.species, species);
    };
    Object.defineProperty(Promise.prototype, 'constructor', { value: {}, configurable: true });
    Promise.prototype.then = new Proxy(Promise.prototype.then, {
      apply(target, receiver, [onFulfilled, onRejected]) {
        return Reflect.apply(target, receiver, [value => {
          window.intercepted.push(value);
          return typeof onFulfilled === 'function' ? onFulfilled(value) : value;
        }, onRejected]);
      }
    });
    Object.defineProperty(Promise, Symbol.species, {
      value: new Proxy(Promise, {
        construct(target, [executor]) {
          return new target((resolve, reject) => {
            executor(value => {
              window.intercepted.push(value);
              resolve(value);
            }, reject);
          });
        }
      }),
      configurable: true
    });
    """

    let consumer = """
    (async () => {
      const values = [];
      let failure;
      try {
        for (const method of ['await', 'then', 'catch', 'finally']) {
          const result = MarkEdit.secretStorage.get(method);
          switch (method) {
            case 'then': values.push(await result.then(value => value)); break;
            case 'catch': values.push(await result.catch(() => undefined)); break;
            case 'finally': values.push(await result.finally(() => {})); break;
            default: values.push(await result);
          }
        }
      } catch (error) {
        failure = String(error);
      } finally {
        window.restorePromiseHooks();
      }
      const message = { values, intercepted: window.intercepted };
      if (failure !== undefined) message.failure = failure;
      window.webkit.messageHandlers.testResults.postMessage(message);
    })();
    """

    for script in EditorUserAsset.contextualScripts(for: [
      ("/attacker.js", EditorUserAsset.script(for: URL(fileURLWithPath: "/attacker.js"), contents: attacker), UUID().uuidString),
      (victim.path, EditorUserAsset.script(for: URL(fileURLWithPath: victim.path), contents: consumer), victim.capability),
    ]) {
      controller.addUserScript(script)
    }

    let webView = WKWebView(frame: .zero, configuration: configuration)
    let html = EditorIndexHtml.fromAppBundle(
      config: AppPreferences.editorConfig(theme: AppTheme.current.editorTheme),
      userSettings: "{}"
    )

    webView.loadHTMLString(html, baseURL: EditorWebView.baseURL)
    await fulfillment(of: [completed], timeout: 10)
    withExtendedLifetime(webView) {}

    let result = try XCTUnwrap(probe.result)
    XCTAssertNil(result["failure"])
    XCTAssertEqual(result["values"] as? [String], Array(repeating: "synthetic-secret", count: 4))

    let intercepted = try XCTUnwrap(result["intercepted"] as? [Any])
    let encoded = try JSONSerialization.data(withJSONObject: intercepted)
    XCTAssertFalse(try XCTUnwrap(String(data: encoded, encoding: .utf8)).contains("synthetic-secret"))
    XCTAssertEqual(probe.keys, ["await", "then", "catch", "finally"])
  }

  private final class SecretReplyProbe: NSObject, WKScriptMessageHandlerWithReply {
    let capability: String
    let completed: XCTestExpectation
    var keys: [String] = []
    var result: [String: Any]?

    init(capability: String, completed: XCTestExpectation) {
      self.capability = capability
      self.completed = completed
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) async -> (Any?, String?) {
      if message.name == "testResults" {
        result = message.body as? [String: Any]
        completed.fulfill()
        return (nil, nil)
      }

      guard let body = message.body as? [String: Any] else {
        XCTFail("Invalid native message")
        return (nil, "Invalid native message")
      }

      guard body["moduleName"] as? String == "secretStorage" else {
        return (nil, nil)
      }

      do {
        let json = try XCTUnwrap(body["parameters"] as? String)
        let parameters = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: String])
        guard body["methodName"] as? String == "get", parameters["capability"] == capability, let key = parameters["key"] else {
          XCTFail("Unexpected secret storage request")
          return (nil, "Unexpected secret storage request")
        }

        keys.append(key)
        return (#"{"value":"synthetic-secret"}"#, nil)
      } catch {
        XCTFail("Invalid secret storage parameters: \(error)")
        return (nil, error.localizedDescription)
      }
    }
  }

  func testScriptsRemainSeparateAndKeepPreparedBindings() async throws {
    AppCustomization.createFiles()
    let original = try Data(contentsOf: AppCustomization.editorScript.fileURL)
    let id = "inspectable-script-test"
    let url = AppCustomization.scriptsDirectory.fileURL.appending(path: "\(id).js")
    defer {
      ExtensionConfig.remove(id: id)
      do {
        try original.write(to: AppCustomization.editorScript.fileURL)
        try FileManager.default.removeItem(at: url)
      } catch {
        XCTFail("Unable to restore test scripts: \(error)")
      }
    }

    try Data("""
    window.scriptOrder = ['first'];
    window.Function = () => { throw new Error('Dynamic compilation is forbidden'); };
    window.require = () => { throw new Error('Replaced require'); };
    window.nativeModules.secretStorage = new Proxy({}, { get() { throw new Error('Replaced storage'); } });
    window.reinitializationTouched = false;
    try {
      window.__prepareScriptContexts__(new Proxy([], {
        get() {
          window.reinitializationTouched = true;
          throw new Error('Repeated preparation must not inspect its input');
        }
      }));
    } catch {
      window.reinitializationBlocked = true;
    }
    """.utf8).write(to: AppCustomization.editorScript.fileURL)
    try Data("""
    const { MarkEdit } = require('markedit-api');
    window.scriptOrder.push('second');
    window.storageResult = MarkEdit.secretStorage.has('').then(
      () => 'unexpected success',
      error => error.message
    );
    """.utf8).write(to: url)
    ExtensionConfig.upsertInstalled(ExtensionConfig.Installed(
      id: id, version: "1", url: nil, sha256: nil, file: url.lastPathComponent, enabled: true, installDate: nil
    ))

    let editor = EditorViewController()
    await editor.waitUntilLoaded()
    let scripts = editor.webView.configuration.userContentController.userScripts
    XCTAssertEqual(scripts.count, 3)
    XCTAssertFalse(scripts[0].source.contains("window.scriptOrder"))
    XCTAssertTrue(scripts[1].source.contains("window.scriptOrder = ['first']"))
    XCTAssertTrue(scripts[2].source.contains("window.scriptOrder.push('second')"))
    XCTAssertTrue(editor.webView.isInspectable)

    let order = try await editor.webView.evaluateJavaScript("window.scriptOrder")
    XCTAssertEqual(order as? [String], ["first", "second"])

    let blocked = try await editor.webView.evaluateJavaScript("window.reinitializationBlocked")
    XCTAssertEqual(blocked as? Bool, true)

    let touched = try await editor.webView.evaluateJavaScript("window.reinitializationTouched")
    XCTAssertEqual(touched as? Bool, false)

    let result = try await editor.webView.callAsyncJavaScript(
      "return await window.storageResult;", arguments: [:], in: nil, contentWorld: .page
    )

    XCTAssertEqual(result as? String, SecretStorageError.invalidKey.localizedDescription)
  }

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

  func testOpenPanelOptionsAndCancellation() async throws {
    let editor = EditorViewController(preloadDelay: 60)
    let api = EditorModuleAPI(delegate: editor)
    let defaults = NSOpenPanel()
    let cases: [(options: String, selection: (files: Bool, directories: Bool), multiple: Bool)] = [
      ("{}", (true, false), false),
      (#"{"selectionType":"files","allowsMultipleSelection":false}"#, (true, false), false),
      (#"{"selectionType":"directories"}"#, (false, true), false),
      (#"{"selectionType":"both","allowsMultipleSelection":true,"title":"Select items","message":"Choose files or folders.","prompt":"Choose"}"#, (true, true), true),
    ]

    for item in cases {
      let parameters = Data(#"{"options":\#(item.options)}"#.utf8)
      let task = Task {
        let result = await api.bridge.invoke(method: "showOpenPanel", parameters: parameters)
        XCTAssertNil(try XCTUnwrap(result).get())
      }

      let deadline = ContinuousClock.now + .seconds(5)
      while !NSApp.windows.contains(where: { $0 is NSOpenPanel && $0.isVisible }), ContinuousClock.now < deadline {
        try await Task.sleep(for: .milliseconds(10))
      }

      let panel = try XCTUnwrap(NSApp.windows.compactMap { $0 as? NSOpenPanel }.first { $0.isVisible })
      XCTAssertNil(panel.sheetParent)
      XCTAssertEqual(panel.canChooseFiles, item.selection.files)
      XCTAssertEqual(panel.canChooseDirectories, item.selection.directories)
      XCTAssertEqual(panel.allowsMultipleSelection, item.multiple)
      XCTAssertTrue(panel.showsHiddenFiles)
      XCTAssertTrue(panel.canCreateDirectories)
      XCTAssertTrue(panel.allowedContentTypes.isEmpty)
      XCTAssertEqual(panel.title, item.multiple ? "Select items" : defaults.title)
      XCTAssertEqual(panel.message, item.multiple ? "Choose files or folders." : defaults.message)
      XCTAssertEqual(panel.prompt, item.multiple ? "Choose" : defaults.prompt)

      panel.cancel(nil)
      try await task.value
    }
  }

  func testOpenPanelRejectsInvalidSelectionType() {
    let data = Data(#"{"selectionType":"invalid"}"#.utf8)
    XCTAssertThrowsError(try JSONDecoder().decode(OpenPanelOptions.self, from: data))
  }

  func testSecretConfirmationApprovalAndCancellation() async throws {
    let editor = EditorViewController(preloadDelay: 60)
    let frame = NSRect(x: 0, y: 0, width: 400, height: 300)
    editor.view = NSView(frame: frame)

    let window = NSWindow(contentRect: frame, styleMask: [.titled], backing: .buffered, defer: false)
    window.isReleasedWhenClosed = false
    window.contentView = editor.view
    window.orderFront(nil)
    defer { window.close() }

    let contexts = [
      (id: "local:editor.js", path: AppCustomization.editorScript.fileURL.path(percentEncoded: false), displayPath: "Documents ‣ editor.js"),
      (id: "test-extension", path: "/scripts/test-extension.js", displayPath: "Documents ‣ scripts ‣ test-extension.js"),
    ]

    for (context, response) in zip(contexts, [NSApplication.ModalResponse.alertFirstButtonReturn, .alertSecondButtonReturn]) {
      let task = Task { try await editor.confirmSecretAccess(extensionID: context.id, path: context.path, key: "api-token") }
      let sheet = try await waitForSecretSheet(window)
      XCTAssertEqual(sheet.defaultButtonCell?.title, Localized.SecretStorage.allowOnce)

      let learnMore: NSButton = try XCTUnwrap(sheet.contentView?.firstDescendant {
        $0.title == Localized.General.learnMore
      })

      XCTAssertNotNil(learnMore.target)
      XCTAssertEqual(learnMore.action, NSSelectorFromString("invoke"))

      let text = sheet.contentView.map(secretConfirmationText) ?? ""
      XCTAssertTrue(text.contains("api-token"))
      XCTAssertTrue(text.contains(String(format: Localized.SecretStorage.title, context.id)))
      XCTAssertTrue(text.contains(String(format: Localized.SecretStorage.message, context.displayPath, "api-token")))
      XCTAssertFalse(text.contains(context.path))

      if response == .alertFirstButtonReturn {
        let button = try XCTUnwrap(sheet.defaultButtonCell?.controlView as? NSButton)
        button.performClick(nil)
      } else {
        window.endSheet(sheet, returnCode: response)
      }

      do {
        try await task.value
        XCTAssertEqual(response, .alertFirstButtonReturn)
      } catch SecretStorageError.cancelled {
        XCTAssertEqual(response, .alertSecondButtonReturn)
      }
    }
  }

  private func waitForSecretSheet(_ window: NSWindow) async throws -> NSWindow {
    let deadline = ContinuousClock.now + .seconds(5)
    while window.attachedSheet == nil, ContinuousClock.now < deadline {
      try await Task.sleep(for: .milliseconds(10))
    }

    return try XCTUnwrap(window.attachedSheet)
  }

  private func secretConfirmationText(_ view: NSView) -> String {
    let text = (view as? NSTextField)?.stringValue ?? ""
    return ([text] + view.subviews.map(secretConfirmationText)).joined(separator: "\n")
  }

  func testSecretStorageWithSystemKeychain() async throws {
    final class Approval: EditorModuleSecretStorageDelegate {
      func confirmSecretAccess(extensionID: String, path: String, key: String) async throws {}
    }

    let context = EditorModuleSecretStorage.Context(id: "test:\(UUID().uuidString)", path: "/scripts/keychain-test.js")
    let approval = Approval()
    let module = EditorModuleSecretStorage(contexts: [context], delegate: approval)
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecUseDataProtectionKeychain as String: true,
      kSecAttrSynchronizable as String: false,
      kSecAttrService as String: "app.cyan.markedit.extension-secrets.\(context.id)",
      kSecAttrAccount as String: "token",
    ]

    let stored = await module.set(capability: context.capability, key: "token", value: "test-token")
    let error = try secretStorageResponse(stored)["error"] as? String
    if error == SecretStorageError.keychain(errSecMissingEntitlement).localizedDescription {
      throw XCTSkip("System Keychain tests require a signed host with Keychain entitlements.")
    }

    defer {
      let status = SecItemDelete(query as CFDictionary)
      XCTAssertTrue(status == errSecSuccess || status == errSecItemNotFound)
    }

    XCTAssertNil(error)
    let exists = await module.has(capability: context.capability, key: "token")
    XCTAssertEqual(try secretStorageResponse(exists)["value"] as? Bool, true)
    let value = await module.get(capability: context.capability, key: "token")
    XCTAssertEqual(try secretStorageResponse(value)["value"] as? String, "test-token")
    let removed = await module.delete(capability: context.capability, key: "token")
    XCTAssertEqual(try secretStorageResponse(removed)["value"] as? Bool, true)
  }

  private func secretStorageResponse(_ json: String) throws -> [String: Any] {
    try XCTUnwrap(JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])
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
