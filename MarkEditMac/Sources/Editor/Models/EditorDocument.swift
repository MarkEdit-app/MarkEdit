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
  var spellDocTag: Int?
  var stringValue = ""
  var formatCompleted = false // The result of format content is all good
  var isOutdated = false // The content is outdated, needs an update
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

  var shouldSaveWhenIdle: Bool {
    // Saving documents without a fileURL would bring up the dialog
    AppRuntimeConfig.autoSaveWhenIdle && fileURL != nil
  }

  private var textBundle: TextBundleWrapper?
  private var revertedDate: Date = .distantPast
  private var suggestedTextEncoding: EditorTextEncoding?
  private weak var hostViewController: EditorViewController?

  /**
   File name from the table of contents.
   */
  private var suggestedFilename: String?

  /**
   File name from external apps, such as Shortcuts or URL schemes.
   */
  private var externalFilename: String?

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

    externalFilename = AppDocumentController.suggestedFilename
    AppDocumentController.suggestedFilename = nil

    NSApplication.shared.closeOpenPanels()
    addWindowController(windowController)
  }

  func waitUntilSaveCompleted(userInitiated: Bool = false, delay: TimeInterval = 0.6) async {
    await withCheckedContinuation { continuation in
      saveContent(userInitiated: userInitiated) {
        continuation.resume()
      }
    }

    // It takes sometime to actually save the document
    await withCheckedContinuation { continuation in
      DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        continuation.resume()
      }
    }
  }

  func saveContent(sender: Any? = nil, userInitiated: Bool = false, completion: (() -> Void)? = nil) {
    Task { @MainActor in
      let saveAction = {
        super.save(sender)
        completion?()
      }

      if isOutdated || (userInitiated && needsFormatting) {
        updateContent(userInitiated: userInitiated, saveAction: saveAction)
      } else {
        saveAction()

        if userInitiated {
          markContentClean()
        }
      }
    }
  }

  func updateContent(userInitiated: Bool = false, saveAction: @escaping (() -> Void) = {}) {
    Task { @MainActor in
      await updateContent(userInitiated: userInitiated)
      saveAction()
    }
  }

  func prepareSpellDocTag() {
    guard spellDocTag == nil else {
      return
    }

    spellDocTag = NSSpellChecker.uniqueSpellDocumentTag()
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
      super.canClose(
        withDelegate: delegate,
        shouldClose: shouldClose,
        contextInfo: contextInfo
      )
    }

    // Closing a new document, force sync to make sure the content is propagated.
    //
    // Don't use `isDraft` here because it's false when closing a document with no files on disk.
    if isNewFile {
      return updateContent(saveAction: canClose)
    }

    // Explicitly save the content before closing.
    //
    // Case 1: The content isn't outdated, so auto-saving won't trigger.
    // Case 2: Occasionally, the ".sb" backup file isn't properly cleaned up.
    if (shouldSaveWhenIdle && isOutdated) || (!closeAlwaysConfirmsChanges && isDocumentEdited) {
      return saveContent(completion: canClose)
    }

    // General cases
    Task { @MainActor in
      canClose()
    }
  }

  override func close() {
    super.close()

    if let spellDocTag {
      NSSpellChecker.shared.closeSpellDocument(withTag: spellDocTag)
    }
  }

  override func writableTypes(for saveOperation: NSDocument.SaveOperationType) -> [String] {
    // Include all markdown and plaintext types, but prioritize the configured default
    let exportedTypes = NewFilenameExtension.allCases
      .sorted { lhs, _ in
        lhs.rawValue == AppPreferences.General.newFilenameExtension.rawValue
      }
      .map { $0.exportedType }

    // Enable *.textbundle only when we have the bundle, typically for a duplicated draft
    return textBundle == nil ? exportedTypes : ["org.textbundle.package"] + exportedTypes
  }

  override func fileNameExtension(forType typeName: String, saveOperation: NSDocument.SaveOperationType) -> String? {
    if typeName.isTextBundle {
      return "textbundle"
    }

    return NewFilenameExtension.preferredExtension(for: typeName).rawValue
  }

  override func prepareSavePanel(_ savePanel: NSSavePanel) -> Bool {
    if let defaultDirectory = AppRuntimeConfig.defaultSaveDirectory {
      // Overriding savePanel.directoryURL does not work as intended
      NSDocumentController.shared.setOpenPanelDirectory(defaultDirectory)
    }

    if textBundle == nil {
      savePanel.accessoryView = EditorSaveOptionsView.wrapper(for: .all) { [weak self, weak savePanel] result in
        switch result {
        case .fileExtension(let value):
          savePanel?.enforceUniformType(value.uniformType)
        case .textEncoding(let value):
          self?.suggestedTextEncoding = value
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
  override func read(from data: Data, ofType typeName: String) throws {
    DispatchQueue.global(qos: .userInitiated).async {
      let newValue = {
        if let encoding = AppDocumentController.suggestedTextEncoding {
          return encoding.decode(data: data)
        }

        let encoding = AppPreferences.General.defaultTextEncoding
        return encoding.decode(data: data, guessEncoding: true)
      }()

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
    guard isOutdated || needsFormatting else {
      super.save(sender)
      markContentClean()
      return
    }

    saveContent(sender: sender, userInitiated: true)
  }

  override func autosave(withImplicitCancellability implicitlyCancellable: Bool) async throws {
    if isOutdated {
      await updateContent()
    }

    // The default autosave doesn't work when the app is about to terminate,
    // it is because we have to do it in an asynchronous way.
    //
    // To work around this, check a flag to save the document manually.
    if !hasBeenReverted && isTerminating && hasUnautosavedChanges, let fileURL, let fileType {
      try? writeSafely(to: fileURL, ofType: fileType, for: .autosaveAsOperation)
      fileModificationDate = .now // Prevent immediate presentedItemDidChange calls
    }

    Task { @MainActor in
      try await super.autosave(withImplicitCancellability: implicitlyCancellable)
    }
  }

  override func data(ofType typeName: String) throws -> Data {
    let encoding = suggestedTextEncoding ?? AppPreferences.General.defaultTextEncoding
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

// MARK: - Scripting

extension EditorDocument {
  /// Handle save operations from AppleScript.
  ///
  /// Override to catch invalid output paths early so we can present more informative errors.
  override func handleSave(_ command: NSScriptCommand) -> Any? {
    guard let fileURL = command.evaluatedArguments?["File"] as? URL else {
      // Save without predefined destination (will open save panel if needed)
      return super.handleSave(command)
    }

    let inputExtension = fileURL.pathExtension.lowercased()

    // Support extension-less paths by bypassing file type validation
    if inputExtension.isEmpty {
      Task { @MainActor in
        try await save(to: fileURL.deletingPathExtension(), ofType: "", for: .saveOperation)
      }
      return nil
    }

    // Provided limited support for the 'as' parameter
    if let desiredType = command.evaluatedArguments?["FileType"] as? String {
      let desiredExtension = NewFilenameExtension.preferredExtension(for: desiredType).rawValue
      if inputExtension == desiredExtension {
        return super.handleSave(command)
      }

      // Raise error because we cannot adjust the extension due to sandbox restrictions
      let scriptError = ScriptingError.extensionMismatch(
        expectedExtension: desiredExtension,
        outputType: desiredType
      )

      scriptError.applyToCommand(command)
      return nil
    }

    let isValidExtension = NewFilenameExtension.allCases.contains {
      $0.rawValue == inputExtension
    } || (textBundle != nil && inputExtension == "textbundle")

    guard isValidExtension else {
      let scriptError = ScriptingError.invalidDestination(fileURL, document: self)
      scriptError.applyToCommand(command)
      return nil
    }

    return super.handleSave(command)
  }
}

// MARK: - Version Browsing

extension EditorDocument: FileVersionPickerDelegate {
  override func browseVersions(_ sender: Any?) {
    guard let fileURL else {
      return Logger.assertFail("Missing fileURL for document: \(self)")
    }

    let localVersions = {
      let otherVersions = NSFileVersion.otherVersionsOfItem(at: fileURL) ?? []
      Logger.log(.debug, "Found \(otherVersions.count) local versions")

      if otherVersions.isEmpty, let currentVersion = NSFileVersion.currentVersionOfItem(at: fileURL) {
        return [currentVersion]
      }

      let sortedVersions = otherVersions.newestToOldest()
      let differentIndex = sortedVersions.firstIndex {
        // Find the first version that differs from the current one
        (try? Data(contentsOf: $0.url))?.toString() != stringValue
      }

      return Array(sortedVersions.suffix(from: differentIndex ?? 0))
    }()

    guard !localVersions.isEmpty else {
      return Logger.assertFail("File \(fileURL) has no local versions")
    }

    let picker = FileVersionPicker(
      modernStyle: AppDesign.modernStyle,
      fileURL: fileURL,
      currentText: stringValue,
      localVersions: localVersions,
      localizable: FileVersionLocalizable(
        previous: Localized.General.previous,
        next: Localized.General.next,
        cancel: Localized.General.cancel,
        revertTitle: Localized.FileVersion.revertTitle,
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
    saveContent()
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

    // Ideally we should be able to print WKWebView,
    // but it doesn't work well because of the lazily rendering strategy used in CodeMirror.
    //
    // For now let's just print plain text,
    // we don't expect printing to be used a lot.

    Task { @MainActor in
      // Alignment
      printInfo.isHorizontallyCentered = true
      printInfo.isVerticallyCentered = false

      // Sizing
      let width = printInfo.paperSize.width - printInfo.leftMargin - printInfo.rightMargin
      let height = printInfo.paperSize.height - printInfo.topMargin - printInfo.bottomMargin
      let frame = CGRect(x: 0, y: 0, width: width, height: height)

      // Rendering
      let textView = NSTextView(frame: frame)
      textView.string = await hostViewController?.editorText ?? stringValue
      textView.sizeToFit()

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

  var needsFormatting: Bool {
    guard !formatCompleted else {
      return false
    }

    return AppPreferences.Assistant.insertFinalNewline || AppPreferences.Assistant.trimTrailingWhitespace
  }

  func updateContent(userInitiated: Bool = false) async {
    let insertFinalNewline = AppPreferences.Assistant.insertFinalNewline
    let trimTrailingWhitespace = AppPreferences.Assistant.trimTrailingWhitespace

    // Format when saving files, only if at least one option is enabled
    if insertFinalNewline || trimTrailingWhitespace {
      formatCompleted = (try? await bridge?.format.formatContent(
        insertFinalNewline: insertFinalNewline,
        trimTrailingWhitespace: trimTrailingWhitespace,
        userInitiated: userInitiated
      )) ?? false
    }

    if let editorText = await hostViewController?.editorText {
      stringValue = editorText

      DispatchQueue.global(qos: .utility).async {
        let fileData = editorText.toData() ?? Data()
        let directory = AppCustomization.debugDirectory.fileURL
        try? fileData.write(to: directory.appending(path: "last-edited.md"))
      }
    }

    // If the content contains headings, use the first one to override the displayName
    if fileURL == nil, let heading = await hostViewController?.tableOfContents?.first {
      suggestedFilename = heading.title
    } else {
      suggestedFilename = nil
    }

    isOutdated = false
    unblockUserInteraction()

    if userInitiated {
      markContentClean()
    }
  }

  func markContentClean() {
    bridge?.history.markContentClean()
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
      // Delay this for two reasons:
      //  1. To make it clear to users that their changes are saved
      //  2. To avoid leftover .sb copies when a document is closed too quickly
      let closeDelayed = {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: performClose)
      }

      // Saved
      document.saveContent(userInitiated: true, completion: closeDelayed)
    }
  }
}
