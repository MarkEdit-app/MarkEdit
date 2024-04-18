//
//  EditorDocument.swift
//  MarkEditMac
//
//  Created by cyan on 12/12/22.

import AppKit
import MarkEditKit
import TextBundle

/**
 Main document used to deal with markdown files and text bundles.

 https://developer.apple.com/documentation/appkit/nsdocument
 */
final class EditorDocument: NSDocument {
  var fileData: Data?
  var stringValue = ""
  var latestRevision: String?
  var isReadOnlyMode = false
  var isDying = false

  var canUndo: Bool {
    get async {
      if isReadOnlyMode {
        return false
      }

      return (try? await bridge?.history.canUndo()) ?? false
    }
  }

  var canRedo: Bool {
    get async {
      if isReadOnlyMode {
        return false
      }

      return (try? await bridge?.history.canRedo()) ?? false
    }
  }

  var lineEndings: LineEndings? {
    get async {
      try? await bridge?.lineEndings.getLineEndings()
    }
  }

  var baseURL: URL? {
    textBundle != nil ? fileURL : folderURL
  }

  var textFileURL: URL? {
    fileURL?.appending(path: textBundle?.textFileName ?? "", directoryHint: .notDirectory)
  }

  private var textBundle: TextBundleWrapper?
  private var suggestedFilename: String?
  private weak var hostViewController: EditorViewController?

  override func makeWindowControllers() {
    let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
    let sceneIdentifier = NSStoryboard.SceneIdentifier("EditorWindowController")

    guard let windowController = storyboard.instantiateController(withIdentifier: sceneIdentifier) as? EditorWindowController else {
      return
    }

    // Note hostViewController is a weak reference, it must be strongly retained first
    let contentVC = EditorReusePool.shared.dequeueViewController()
    windowController.contentViewController = contentVC

    // Restore the autosaved window frame, which relies on windowFrameAutosaveName
    if let autosavedFrame = windowController.autosavedFrame {
      windowController.window?.setFrame(autosavedFrame, display: false)
    }

    isDying = false
    hostViewController = contentVC
    hostViewController?.representedObject = self

    NSApplication.shared.closeOpenPanels()
    addWindowController(windowController)
  }
}

// MARK: - Overridden

extension EditorDocument {
  override class var autosavesInPlace: Bool {
    true
  }

  override class func canConcurrentlyReadDocuments(ofType type: String) -> Bool {
    true
  }

  override var displayName: String? {
    get {
      suggestedFilename ?? super.displayName
    }
    set {
      super.displayName = newValue
    }
  }

  override func canAsynchronouslyWrite(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType) -> Bool {
    true
  }

  override func canClose(withDelegate delegate: Any, shouldClose shouldCloseSelector: Selector?, contextInfo: UnsafeMutableRawPointer?) {
    let canClose = {
      super.canClose(
        withDelegate: delegate,
        shouldClose: shouldCloseSelector,
        contextInfo: contextInfo
      )
    }

    guard fileURL == nil else {
      // Closing an existing document
      return canClose()
    }

    // Closing a new document, force sync to make sure the content is propagated.
    //
    // Don't use `isDraft` here because it's false when closing a document with no files on disk.
    Task {
      await saveAsynchronously(userInitiated: true, saveAction: canClose)
    }
  }

  override func writableTypes(for saveOperation: NSDocument.SaveOperationType) -> [String] {
    // Enable *.textbundle only when we have the bundle, typically for a duplicated draft
    textBundle == nil ? [AppPreferences.General.newFilenameExtension.exportedType] : ["org.textbundle.package"]
  }

  override func fileNameExtension(forType typeName: String, saveOperation: NSDocument.SaveOperationType) -> String? {
    typeName.isTextBundle ? "textbundle" : AppPreferences.General.newFilenameExtension.rawValue
  }
}

// MARK: - Reading and Writing

extension EditorDocument {
  override func read(from data: Data, ofType typeName: String) throws {
    DispatchQueue.global(qos: .userInitiated).async {
      let encoding = AppPreferences.General.defaultTextEncoding
      let newValue = encoding.decode(data: data) ?? data.toString() ?? ""
      guard self.stringValue != newValue else { return }

      DispatchQueue.main.async {
        self.fileData = data
        self.stringValue = newValue
        self.latestRevision = self.isInViewingMode ? Revisions.latest : nil
        self.hostViewController?.representedObject = self
      }
    }
  }

  // We don't have a sync way to get the text, override save and autosave to do an async approach.
  //
  // Note that, by only overriding the "saveToURL" method can bring hang issues.
  override func save(_ sender: Any?) {
    Task {
      await saveAsynchronously(userInitiated: true) {
        super.save(sender)
      }

      if sender != nil {
        hostViewController?.cancelCompletion()
      }
    }
  }

  override func autosave(withImplicitCancellability implicitlyCancellable: Bool) async throws {
    await saveAsynchronously(userInitiated: false) {
      // The default autosave doesn't work when the app is about to terminate,
      // it is because we have to do it in an asynchronous way.
      //
      // To work around this, check a flag to save the document manually.
      if isDying && hasUnautosavedChanges, let fileURL, let fileType {
        try? writeSafely(to: fileURL, ofType: fileType, for: .autosaveAsOperation)
        fileModificationDate = .now // Prevent immediate presentedItemDidChange calls
      }

      Task {
        try await super.autosave(withImplicitCancellability: implicitlyCancellable)
      }
    }
  }

  override func data(ofType typeName: String) throws -> Data {
    let encoding = AppPreferences.General.defaultTextEncoding
    return encoding.encode(string: stringValue) ?? stringValue.toData() ?? Data()
  }

  override func presentedItemDidChange() {
    guard let fileURL, let fileType else {
      return
    }

    // Only under certain conditions we need this flow,
    // e.g., editing in VS Code won't trigger the regular data(ofType...) reload
    DispatchQueue.main.async {
      do {
        // For text bundles, use the text.markdown file inside it
        let filePath = self.textBundle?.textFilePath(baseURL: fileURL) ?? fileURL.path
        let modificationDate = try FileManager.default.attributesOfItem(atPath: filePath)[.modificationDate] as? Date

        if let modificationDate, modificationDate > (self.fileModificationDate ?? .distantPast) {
          self.fileModificationDate = modificationDate
          try self.revert(toContentsOf: fileURL, ofType: fileType)
        }
      } catch {
        Logger.log(.error, error.localizedDescription)
      }
    }
  }
}

// MARK: Version Browsing

extension EditorDocument {
  override func browseVersions(_ sender: Any?) {
    // We don't have a way to retrieve the latest revision,
    // save a copy before opening the version browser.
    //
    // This works when only one version browser can be open at a time,
    // which seems to be the case so far.
    Revisions.latest = stringValue
    super.browseVersions(sender)
  }
}

// MARK: - Text Bundle

extension EditorDocument {
  override func read(from fileWrapper: FileWrapper, ofType typeName: String) throws {
    guard typeName.isTextBundle else {
      return try super.read(from: fileWrapper, ofType: typeName)
    }

    textBundle = try TextBundleWrapper(fileWrapper: fileWrapper)
    try read(from: textBundle?.data ?? Data(), ofType: typeName)
  }

  override func write(to url: URL, ofType typeName: String) throws {
    guard typeName.isTextBundle else {
      return try super.write(to: url, ofType: typeName)
    }

    let fileWrapper = try? textBundle?.fileWrapper(with: try data(ofType: typeName))
    try fileWrapper?.write(to: url, originalContentsURL: nil)
  }

  override func duplicate() throws -> NSDocument {
    guard textBundle != nil, let fileURL else {
      return try super.duplicate()
    }

    return try NSDocumentController.shared.duplicateDocument(
      withContentsOf: fileURL,
      copying: true,
      displayName: fileURL.deletingPathExtension().lastPathComponent
    )
  }
}

// MARK: - Printing

extension EditorDocument {
  @IBAction override func printDocument(_ sender: Any?) {
    guard let window = hostViewController?.view.window else {
      return
    }

    Task {
      // Ideally we should be able to print WKWebView,
      // but it doesn't work well because of the lazily rendering strategy used in CodeMirror.
      //
      // For now let's just print plain text,
      // we don't expect printing to be used a lot.
      let textView = NSTextView(frame: CGRect(origin: .zero, size: printInfo.paperSize))
      textView.string = await hostViewController?.editorText ?? stringValue

      let operation = NSPrintOperation(view: textView)
      operation.runModal(for: window, delegate: nil, didRun: nil, contextInfo: nil)
    }
  }
}

// MARK: - Private

private extension EditorDocument {
  var bridge: WebModuleBridge? {
    hostViewController?.bridge
  }

  func saveAsynchronously(userInitiated: Bool, saveAction: () -> Void) async {
    // In viewing mode (aka version browsing), saveAction is directly skipped
    guard !isInViewingMode else {
      return
    }

    let insertFinalNewline = AppPreferences.Assistant.insertFinalNewline
    let trimTrailingWhitespace = AppPreferences.Assistant.trimTrailingWhitespace

    // Format when saving files, only if at least one option is enabled
    if userInitiated && (insertFinalNewline || trimTrailingWhitespace) {
      await withCheckedContinuation { continuation in
        bridge?.format.formatContent(
          insertFinalNewline: insertFinalNewline,
          trimTrailingWhitespace: trimTrailingWhitespace
        ) { _ in
          continuation.resume()
        }
      }
    }

    if let editorText = await hostViewController?.editorText {
      stringValue = editorText
    }

    // If a leading H1 is given, use it as the suggested filename, it will be used to override the displayName
    if fileURL == nil, let heading = await hostViewController?.tableOfContents?.first, heading.level == 1 {
      suggestedFilename = heading.title
    } else {
      suggestedFilename = nil
    }

    saveAction()
    unblockUserInteraction()

    if userInitiated {
      bridge?.history.markContentClean()
    }
  }
}

private enum Revisions {
  static var latest: String?
}
