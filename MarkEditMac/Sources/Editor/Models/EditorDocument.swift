//
//  EditorDocument.swift
//  MarkEditMac
//
//  Created by cyan on 12/12/22.

import AppKit
import AppKitExtensions
import MarkEditKit
import Synchronization
import TextBundle

/**
 Main document used to deal with markdown files and text bundles.

 https://developer.apple.com/documentation/appkit/nsdocument
 */
final class EditorDocument: NSDocument {
  var stringValue = ""
  var formatCompleted = false // The result of format content is all good

  // The content is outdated, needs an update
  var isOutdated = false {
    didSet {
      if isOutdated {
        contentChangeCount &+= 1
      }
    }
  }

  var isReadOnlyMode = false
  var isTerminating = false

  // For tab restoration
  var lastTabIndex: Int?
  var lastWasStandalone: Bool = false
  weak var lastSiblingWindow: NSWindow?

  /**
   File name from external apps, such as Shortcuts or URL schemes.
   */
  var externalFilename: String? {
    didSet {
      windowControllers.forEach {
        $0.synchronizeWindowTitleWithDocumentName()
      }
    }
  }

  private(set) weak var hostViewController: EditorViewController?
  private(set) lazy var sessionID = UUID() // Defer until Quick Search needs it
  private(set) var spellDocTag: Int?

  var fileData: Data? {
    get {
      fileSnapshots.withLock { $0.saved }
    }
    set {
      fileSnapshots.withLock { $0.saved = newValue }
    }
  }

  var isContentReady: Bool {
    isDraft || fileURL == nil || fileData != nil
  }

  var hasBeenReverted: Bool {
    Date.now.timeIntervalSince(revertedDate) < 1
  }

  var hasTextBundle: Bool {
    textBundle != nil
  }

  var baseURL: URL? {
    textBundle != nil ? fileURL : folderURL
  }

  var textFileURL: URL? {
    fileURL?.appending(path: textBundle?.textFileName ?? "", directoryHint: .notDirectory)
  }

  var shouldSaveWhenIdle: Bool {
    // Saving documents without a fileURL would bring up the dialog
    AppRuntimeConfig.autoSaveWhenIdle && fileURL != nil
  }

  private let fileSnapshots = Mutex(EditorFileSnapshots())
  private let pendingFileReads = DispatchGroup()
  private var textBundle: TextBundleWrapper?
  private var suggestedTextEncoding: EditorTextEncoding?
  private var revertedDate: Date = .distantPast
  private var autosaveDelayedTask: Task<Void, Never>?
  private var contentChangeCount: UInt64 = 0
  private var pendingPresenterSaves: Int = 0
  private var suggestedFilename: String?
}

// MARK: - External

extension EditorDocument {
  func prepareSpellDocTag() {
    guard spellDocTag == nil else {
      return
    }

    spellDocTag = NSSpellChecker.uniqueSpellDocumentTag()
  }

  func autosaveDelayed(seconds: Double = 0.25) {
    autosaveDelayedTask?.cancel()
    autosaveDelayedTask = Task { [weak self] in
      try? await Task.sleep(for: .seconds(seconds))
      if !Task.isCancelled {
        try? await self?.autosave(withImplicitCancellability: false)
      }
    }
  }
}

// MARK: - Content Synchronization

extension EditorDocument {
  func synchronizeText() async -> String? {
    let changeCount = contentChangeCount
    if let editorText = await hostViewController?.editorText {
      stringValue = editorText
      isOutdated = contentChangeCount != changeCount
      return editorText
    }

    return nil
  }

  func updateSuggestedFilename() async {
    // If the content contains headings, use the first one to override the displayName
    if fileURL == nil, let heading = await hostViewController?.tableOfContents?.first {
      suggestedFilename = heading.title
    } else {
      suggestedFilename = nil
    }
  }
}

// MARK: - Lifecycle

extension EditorDocument {
  override func makeWindowControllers() {
    let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
    let sceneIdentifier = NSStoryboard.SceneIdentifier("EditorWindowController")

    guard let windowController = storyboard.instantiateController(withIdentifier: sceneIdentifier) as? EditorWindowController else {
      return
    }

    // Note hostViewController is a weak reference, it must be strongly retained first
    let contentVC = EditorPreloader.shared.takeViewController()
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

  #if DEBUG
    if ProcessInfo.processInfo.environment["DEBUG_TAKING_SCREENSHOTS"] == "YES" {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        windowController.window?.setFrameSize(CGSize(width: 720, height: 480))
        windowController.window?.center()
      }
    }
  #endif
  }

  override func canClose(
    withDelegate delegate: Any,
    shouldClose shouldCloseSelector: Selector?,
    contextInfo: UnsafeMutableRawPointer?
  ) {
    handleCloseRequest(
      withDelegate: delegate,
      shouldClose: shouldCloseSelector,
      contextInfo: contextInfo
    )
  }

  override func close() {
    if !isTerminating {
      saveToClosedTabHistory()
    }

    if let spellDocTag {
      NSSpellChecker.shared.closeSpellDocument(withTag: spellDocTag)
    }

    super.close()
  }
}

// MARK: - File Properties

extension EditorDocument {
  var newFilenameExtension: String {
    AppPreferences.General.newFilenameExtension.rawValue
  }

  override class var autosavesInPlace: Bool {
    true
  }

  override class func canConcurrentlyReadDocuments(ofType type: String) -> Bool {
    true
  }

  override func canAsynchronouslyWrite(
    to url: URL,
    ofType typeName: String,
    for saveOperation: NSDocument.SaveOperationType
  ) -> Bool {
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
          markContentDirty(false)
          hostViewController?.handleFileURLChange()
        }
      }
    }
  }

  override var displayName: String? {
    get {
      // Default file name for new drafts, pre-filled in the save panel
      if fileURL == nil, let newFileName = suggestedFilename ?? externalFilename {
        return newFileName
      }

      return super.displayName
    }
    set {
      super.displayName = newValue
    }
  }

  override func updateChangeCount(_ change: NSDocument.ChangeType) {
    // The "Edited" label is hidden when changes are saved periodically
    super.updateChangeCount(shouldSaveWhenIdle ? .changeCleared : change)
  }

  override func writableTypes(for saveOperation: NSDocument.SaveOperationType) -> [String] {
    // Include all markdown and plaintext types, but prioritize the configured default
    let exportedTypes = NewFilenameExtension.allCases
      .sorted { lhs, _ in
        lhs.rawValue == newFilenameExtension
      }
      .map { $0.exportedType }

    // Enable *.textbundle only when we have the bundle, typically for a duplicated draft
    return textBundle == nil ? exportedTypes : ["org.textbundle.package"] + exportedTypes
  }

  override func fileNameExtension(
    forType typeName: String,
    saveOperation: NSDocument.SaveOperationType
  ) -> String? {
    if typeName.isTextBundle {
      return "textbundle"
    }

    if let preferredExtension = NewFilenameExtension.preferredExtension(for: typeName) {
      return preferredExtension.rawValue
    }

    return fileURL?.pathExtension ?? newFilenameExtension
  }

  override func prepareSavePanel(_ savePanel: NSSavePanel) -> Bool {
    if let defaultDirectory = AppRuntimeConfig.defaultSaveDirectory {
      // Overriding savePanel.directoryURL does not work as intended
      NSDocumentController.shared.setOpenPanelDirectory(defaultDirectory)
    }

    if textBundle == nil {
      savePanel.accessoryView = EditorSaveOptionsView.wrapper(for: .savePanel) { [weak self, weak savePanel] result in
        switch result {
        case .fileExtension(let value):
          savePanel?.enforceUniformType(value.uniformType)
        case .textEncoding(let value):
          self?.suggestedTextEncoding = value
        default:
          Logger.assertFail("Invalid change: \(result)")
        }
      }
    } else {
      savePanel.accessoryView = nil
    }

    suggestedTextEncoding = nil
    savePanel.allowsOtherFileTypes = true
    return super.prepareSavePanel(savePanel)
  }
}

// MARK: - Reading and Writing

extension EditorDocument {
  override func data(ofType typeName: String) throws -> Data {
    let encoding = suggestedTextEncoding ?? AppPreferences.General.defaultTextEncoding
    return encoding.encode(string: stringValue) ?? stringValue.toData() ?? Data()
  }

  override func fileWrapper(ofType typeName: String) throws -> FileWrapper {
    let wrapper = try super.fileWrapper(ofType: typeName)
    fileSnapshots.withLock {
      // Keep the serialized bytes, not text that may change while the write finishes
      if $0.isWriting {
        $0.pending = wrapper.regularFileContents
      }
    }

    return wrapper
  }

  override func read(from data: Data, ofType typeName: String) throws {
    pendingFileReads.enter()
    DispatchQueue.global(qos: .userInitiated).async {
      let newValue = {
        if let encoding = AppDocumentController.suggestedTextEncoding {
          return encoding.decode(data: data)
        }

        let encoding = AppPreferences.General.defaultTextEncoding
        return encoding.decode(data: data, guessEncoding: true)
      }()

      DispatchQueue.main.async {
        defer { self.pendingFileReads.leave() }
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
    guard isOutdated || needsFormatting else {
      super.save(sender)
      markContentClean()
      return
    }

    saveContent(sender: sender, userInitiated: true)
  }

  override func save(
    withDelegate delegate: Any?,
    didSave selector: Selector?,
    contextInfo: UnsafeMutableRawPointer?
  ) {
    // AppKit can check for conflicts before reaching the save-to-URL override
    reconcileFileModificationDate()
    super.save(withDelegate: delegate, didSave: selector, contextInfo: contextInfo)
  }

  override func save(
    to url: URL,
    ofType typeName: String,
    for saveOperation: NSDocument.SaveOperationType,
    completionHandler: @escaping (Error?) -> Void
  ) {
    if url == fileURL, saveOperation.isInPlace {
      reconcileFileModificationDate()
    }

    super.save(to: url, ofType: typeName, for: saveOperation) { error in
      if !typeName.isTextBundle, saveOperation.updatesDocumentFile {
        // AppKit has now updated the URL and date, so the saved bytes belong to that file
        self.fileSnapshots.withLock {
          $0.saveDidFinish(succeeded: error == nil)
        }
      }

      completionHandler(error)
    }
  }

  // Deliberately use the callback override to preserve AppKit's nested file-access context,
  // deferring the call to super can deadlock during coordinated file access.
  override func autosave(
    withImplicitCancellability implicitlyCancellable: Bool,
    completionHandler: @escaping (Error?) -> Void
  ) {
    let saveAction = {
      do {
        // Reject stale text after a failed refresh or an intervening edit
        try self.requireSynchronized(implicitlyCancellable: implicitlyCancellable)

        if try self.writeSafelyBeforeTermination() {
          completionHandler(nil)
          return
        }

        super.autosave(
          withImplicitCancellability: implicitlyCancellable,
          completionHandler: completionHandler
        )
      } catch {
        completionHandler(error)
      }
    }

    // A presenter autosave must not suspend if another edit arrives after its entry check
    if isOutdated && pendingPresenterSaves == 0 {
      updateContent(saveAction: saveAction)
    } else {
      saveAction()
    }
  }

  override func writeSafely(
    to url: URL,
    ofType typeName: String,
    for saveOperation: NSDocument.SaveOperationType
  ) throws {
    guard !typeName.isTextBundle, saveOperation.updatesDocumentFile else {
      return try super.writeSafely(to: url, ofType: typeName, for: saveOperation)
    }

    fileSnapshots.withLock {
      $0.pending = nil
      $0.isWriting = true
    }

    var succeeded = false
    defer {
      fileSnapshots.withLock {
        if !succeeded {
          $0.pending = nil
        }

        $0.isWriting = false
      }
    }

    try super.writeSafely(to: url, ofType: typeName, for: saveOperation)
    succeeded = true
  }

  override func revert(toContentsOf url: URL, ofType typeName: String) throws {
    revertedDate = .now
    try super.revert(toContentsOf: url, ofType: typeName)
  }
}

// MARK: - Document Actions

extension EditorDocument {
  override func browseVersions(_ sender: Any?) {
    presentFileVersions(sender)
  }

  override func handleSave(_ command: NSScriptCommand) -> Any? {
    handleScriptedSave(command)
  }

  override func print(
    withSettings printSettings: [NSPrintInfo.AttributeKey: Any],
    showPrintPanel: Bool,
    delegate: Any?,
    didPrint didPrintSelector: Selector?,
    contextInfo: UnsafeMutableRawPointer?
  ) {
    // Ideally we should be able to print WKWebView,
    // but it doesn't work well because of the lazily rendering strategy used in CodeMirror.
    //
    // For now let's just print plain text,
    // we don't expect printing to be used a lot.
    Task { @MainActor in
      await withCheckedContinuation { continuation in
        pendingFileReads.notify(queue: .main) {
          continuation.resume()
        }
      }

      let operation = await EditorDocumentPrinter.makeOperation(
        printInfo: printInfo,
        settings: printSettings,
        showPrintPanel: showPrintPanel
      ) {
        await self.hostViewController?.editorText ?? self.stringValue
      }

      guard let operation else {
        return Logger.assertFail("Missing operation to handle printing")
      }

      runModalPrintOperation(
        operation,
        delegate: delegate,
        didRun: didPrintSelector,
        contextInfo: contextInfo
      )
    }
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

    guard let textBundle else {
      Logger.assertFail("Missing textBundle for document: \(self)")
      throw CocoaError(.fileWriteUnknown, userInfo: [
        NSLocalizedDescriptionKey: "Unable to save as TextBundle, file wrapper is missing."
      ])
    }

    let fileWrapper = try textBundle.fileWrapper(with: try data(ofType: typeName))
    try fileWrapper.write(to: url, originalContentsURL: nil)
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

// MARK: - File State

extension EditorDocument {
  override func presentedItemDidChange() {
    // Only under certain conditions we need this flow,
    // e.g., editing in VS Code won't trigger the regular data(ofType...) reload
    DispatchQueue.main.async {
      // A pending decode can still replace the text being compared, retry without blocking main
      guard self.pendingFileReads.wait(timeout: .now()) == .success else {
        self.pendingFileReads.notify(queue: .main) {
          self.presentedItemDidChange()
        }

        return
      }

      guard let fileURL = self.fileURL, let fileType = self.fileType else {
        return
      }

      if !fileType.isTextBundle {
        guard !self.hasDifferentAutosavedFile else {
          return
        }

        let documentDate = self.fileModificationDate
        if self.reconcileFileModificationDate() {
          return
        }

        guard self.fileURL == fileURL, self.fileType == fileType,
              self.fileModificationDate == documentDate else {
          return
        }
      }

      do {
        // For text bundles, use the text.markdown file inside it
        let filePath = self.textBundle?.textFilePath(baseURL: fileURL) ?? fileURL.path
        let modificationDate = try FileManager.default.attributesOfItem(atPath: filePath)[.modificationDate] as? Date
        guard let modificationDate, modificationDate > (self.fileModificationDate ?? .distantPast) else {
          return
        }

        self.fileModificationDate = modificationDate
        if !fileType.isTextBundle && !self.isOutdated {
          do {
            if let matchingData = try self.matchingFileData {
              self.fileData = matchingData
              self.markContentClean()
              self.markContentDirty(false)
              return
            }
          } catch {
            Logger.log(.error, "Failed to compare file and document contents: \(error.localizedDescription)")
          }
        }

        try self.revert(toContentsOf: fileURL, ofType: fileType)
      } catch {
        Logger.log(.error, error.localizedDescription)
      }
    }
  }

  override nonisolated func savePresentedItemChanges(
    completionHandler: @escaping @Sendable (Error?) -> Void
  ) {
    continueOnMainActor {
      do {
        // WebKit cannot reliably finish a text read while AppKit blocks main,
        // an ordinary save can sync it later.
        try self.requireSynchronized()
      } catch {
        completionHandler(error)
        return
      }

      self.pendingPresenterSaves += 1
      super.savePresentedItemChanges { error in
        self.continueOnMainActor {
          self.pendingPresenterSaves -= 1
          completionHandler(error)
        }
      }
    }
  }

  private func requireSynchronized(implicitlyCancellable: Bool = false) throws {
    // A no-op autosave does not need current editor text
    guard !isOutdated || !hasUnautosavedChanges else {
      Logger.log(.error, "Cannot autosave while editor text is still outdated")

      // AppKit does not present cancellation errors for optional autosaves
      throw CocoaError(implicitlyCancellable ? .userCancelled : .fileWriteUnknown)
    }
  }

  /// Verify timestamp-only drift without reloading or changing the editor's dirty state.
  /// Returns true for an unchanged timestamp or verified unchanged contents.
  @discardableResult
  private func reconcileFileModificationDate() -> Bool {
    guard let fileURL, let fileType, !fileType.isTextBundle,
          let documentDate = fileModificationDate,
          fileData != nil, !hasDifferentAutosavedFile else {
      return false
    }

    let matchesFileState = {
      self.fileURL == fileURL &&
      self.fileType == fileType &&
      self.fileModificationDate == documentDate
    }

    do {
      let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
      guard attributes[.modificationDate] as? Date != documentDate else {
        return true
      }

      var unchangedDate: Date?
      try withCoordinatedFileRead(at: fileURL) { url, date in
        guard matchesFileState(), date != documentDate else {
          return
        }

        let diskData = try Data(contentsOf: url)
        guard matchesFileState() else {
          return
        }

        let knownData = self.fileSnapshots.withLock {
          (saved: $0.saved, pending: $0.pending)
        }

        if diskData == knownData.saved || diskData == knownData.pending {
          unchangedDate = date
        }
      }

      guard let unchangedDate, matchesFileState() else {
        return false
      }

      fileModificationDate = unchangedDate
      return true
    } catch {
      Logger.log(.error, "Failed to check external file changes: \(error.localizedDescription)")
      return false
    }
  }

  private func writeSafelyBeforeTermination() throws -> Bool {
    guard !hasBeenReverted, isTerminating, hasUnautosavedChanges, let fileURL, let fileType else {
      return false
    }

    // Asynchronous autosaving may not finish during termination
    try writeSafely(to: fileURL, ofType: fileType, for: .autosaveAsOperation)

    // This direct write has no save completion callback
    if !fileType.isTextBundle {
      fileSnapshots.withLock {
        $0.saveDidFinish(succeeded: true)
      }
    }

    // Prevent immediate presentedItemDidChange calls
    fileModificationDate = .now
    return true
  }
}
