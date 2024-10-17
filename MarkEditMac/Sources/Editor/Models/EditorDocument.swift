//
//  EditorDocument.swift
//  MarkEditMac
//
//  Created by cyan on 12/12/22.

import AppKit
import MarkEditKit
import FileVersion
import TextBundle

/**
 Main document used to deal with markdown files and text bundles.

 https://developer.apple.com/documentation/appkit/nsdocument
 */
final class EditorDocument: NSDocument {
  var fileData: Data?
  var stringValue = ""
  var isReadOnlyMode = false
  var isTerminating = false

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
  private var revertedDate: Date = .distantPast
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

    isTerminating = false
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

  override var fileURL: URL? {
    get {
      super.fileURL
    }
    set {
      let wasDraft = super.fileURL == nil && newValue != nil
      super.fileURL = newValue

      // Newly created files should have a clean state
      if wasDraft {
        Task { @MainActor in
          hostViewController?.handleFileURLChange()
        }
      }
    }
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
    let isNewFile = fileURL == nil
    let shouldClose: Selector? = {
      if !isNewFile && !isTerminating && closeAlwaysConfirmsChanges {
        return #selector(confirmsChanges(_:shouldClose:))
      }

      return shouldCloseSelector
    }()

    let canClose = {
      // After a small delay to work around a rare hang issue
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
        super.canClose(
          withDelegate: delegate,
          shouldClose: shouldClose,
          contextInfo: contextInfo
        )
      }
    }

    guard isNewFile else {
      // Closing an existing document
      return canClose()
    }

    // Closing a new document, force sync to make sure the content is propagated.
    //
    // Don't use `isDraft` here because it's false when closing a document with no files on disk.
    Task {
      await updateContent(userInitiated: true, saveAction: canClose)
    }
  }

  override func writableTypes(for saveOperation: NSDocument.SaveOperationType) -> [String] {
    // Enable *.textbundle only when we have the bundle, typically for a duplicated draft
    textBundle == nil ? [AppPreferences.General.newFilenameExtension.exportedType] : ["org.textbundle.package"]
  }

  override func fileNameExtension(forType typeName: String, saveOperation: NSDocument.SaveOperationType) -> String? {
    typeName.isTextBundle ? "textbundle" : AppPreferences.General.newFilenameExtension.rawValue
  }

  override func prepareSavePanel(_ savePanel: NSSavePanel) -> Bool {
    if let defaultDirectory = AppRuntimeConfig.defaultSaveDirectory {
      // Overriding savePanel.directoryURL does not work as intended
      NSDocumentController.shared.setOpenPanelDirectory(defaultDirectory)
    }

    return super.prepareSavePanel(savePanel)
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
        self.hostViewController?.representedObject = self
      }
    }
  }

  // We don't have a sync way to get the text, override save and autosave to do an async approach.
  //
  // Note that, by only overriding the "saveToURL" method can bring hang issues.
  override func save(_ sender: Any?) {
    saveContent(sender)
  }

  override func autosave(withImplicitCancellability implicitlyCancellable: Bool) async throws {
    await updateContent(userInitiated: false) {
      // The default autosave doesn't work when the app is about to terminate,
      // it is because we have to do it in an asynchronous way.
      //
      // To work around this, check a flag to save the document manually.
      if !hasBeenReverted && isTerminating && hasUnautosavedChanges, let fileURL, let fileType {
        try? writeSafely(to: fileURL, ofType: fileType, for: .autosaveAsOperation)
        fileModificationDate = .now // Prevent immediate presentedItemDidChange calls
      }

      // When "Ask to keep changes when closing documents" is enabled,
      // changes are asked to save explicitly, see also "confirmsChanges(_:shouldClose:)".
      //
      // The value can from either system settings or app level overwritten.
      guard !closeAlwaysConfirmsChanges else {
        return
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

  override func revert(toContentsOf url: URL, ofType typeName: String) throws {
    revertedDate = .now
    try super.revert(toContentsOf: url, ofType: typeName)
  }
}

// MARK: Version Browsing

extension EditorDocument: FileVersionPickerDelegate {
  override func browseVersions(_ sender: Any?) {
    guard let fileURL else {
      return Logger.assertFail("Missing fileURL for document: \(self)")
    }

    let versions = NSFileVersion.otherVersionsOfItem(at: fileURL) ?? []
    Logger.log(.debug, "Found \(versions.count) local versions")

    let picker = FileVersionPicker(
      fileURL: fileURL,
      current: stringValue,
      versions: versions.newestToOldest,
      localizable: FileVersionLocalizable(
        previous: Localized.General.previous,
        next: Localized.General.next,
        cancel: Localized.General.cancel,
        pickThisVersion: Localized.FileVersion.pickThisVersion,
        modeTitles: Localized.FileVersion.modeTitles
      ),
      delegate: self
    )

    hostViewController?.presentAsSheet(picker)
  }

  func fileVersionPicker(_ picker: FileVersionPicker, didPickVersion version: NSFileVersion) {
    guard let contents = try? Data(contentsOf: version.url).toString() else {
      return Logger.assertFail("Failed to get file contents of version: \(version)")
    }

    stringValue = contents
    hostViewController?.resetEditor()
    save(nil)
  }

  func fileVersionPicker(_ picker: FileVersionPicker, didBecomeSheet: Bool) {
    hostViewController?.setHasModalSheet(value: didBecomeSheet)
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

  var closeAlwaysConfirmsChanges: Bool {
    UserDefaults.standard.bool(forKey: NSCloseAlwaysConfirmsChanges)
  }

  var hasBeenReverted: Bool {
    Date.now.timeIntervalSince(revertedDate) < 1
  }

  func saveContent(_ sender: Any?, completion: (() -> Void)? = nil) {
    Task {
      await updateContent(userInitiated: true) {
        super.save(sender)
        completion?()
      }

      if sender != nil {
        hostViewController?.cancelCompletion()
      }
    }
  }

  func updateContent(userInitiated: Bool, saveAction: () -> Void) async {
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

  @objc func confirmsChanges(_ document: EditorDocument, shouldClose: Bool) {
    guard shouldClose else {
      return // Cancelled
    }

    let performClose = {
      // isReleasedWhenClosed is not initially set to true to prevent crashes when deleting drafts.
      // However, we need to release the window in the confirmsChanges function;
      // otherwise, it will cause a memory leak.
      document.windowControllers.forEach {
        $0.window?.isReleasedWhenClosed = true
      }

      document.close()
    }

    if document.hasBeenReverted || !document.isDocumentEdited {
      // Reverted or no unsaved changes
      performClose()
    } else {
      // Saved
      document.saveContent(nil, completion: performClose)
    }
  }
}
