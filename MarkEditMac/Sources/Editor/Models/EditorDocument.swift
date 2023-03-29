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
  var textBundle: TextBundleWrapper?
  var stringValue = ""

  var canUndo: Bool {
    get async {
      (try? await hostViewController?.bridge.history.canUndo()) ?? false
    }
  }

  var canRedo: Bool {
    get async {
      (try? await hostViewController?.bridge.history.canRedo()) ?? false
    }
  }

  var lineEndings: LineEndings? {
    get async {
      try? await hostViewController?.bridge.lineEndings.getLineEndings()
    }
  }

  var folderURL: URL? {
    textBundle != nil ? fileURL : fileURL?.deletingLastPathComponent()
  }

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

  override func canAsynchronouslyWrite(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType) -> Bool {
    true
  }

  override func fileNameExtension(forType typeName: String, saveOperation: NSDocument.SaveOperationType) -> String? {
    "md"
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
    Task {
      await saveAsynchronously {
        super.save(sender)
      }

      if sender != nil {
        hostViewController?.cancelCompletion()
      }
    }
  }

  override func autosave(withImplicitCancellability implicitlyCancellable: Bool) async throws {
    await saveAsynchronously {
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
    DispatchQueue.onMainThread {
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

    // We currently don't support creating text bundles,
    // this will just duplicate the Markdown file inside it.
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
    // but it doesn't work very well even on Ventura.
    //
    // For now let's just print plain text,
    // we don't expect printing to be used a lot.
    let textView = NSTextView(frame: CGRect(origin: .zero, size: printInfo.paperSize))
    textView.string = stringValue

    let operation = NSPrintOperation(view: textView)
    operation.runModal(for: window, delegate: nil, didRun: nil, contextInfo: nil)
  }
}

// MARK: - Private

private extension EditorDocument {
  func saveAsynchronously(saveAction: () -> Void) async {
    let insertFinalNewline = AppPreferences.Assistant.insertFinalNewline
    let trimTrailingWhitespace = AppPreferences.Assistant.trimTrailingWhitespace

    // Format when saving files, only if at least one option is enabled
    if insertFinalNewline || trimTrailingWhitespace {
      await withCheckedContinuation { continuation in
        hostViewController?.bridge.format.formatContent(
          insertFinalNewline: insertFinalNewline,
          trimTrailingWhitespace: trimTrailingWhitespace
        ) { _ in
          continuation.resume()
        }
      }
    }

    guard let editorText = await hostViewController?.editorText else {
      return
    }

    stringValue = editorText
    saveAction()

    // The editor is no longer dirty because changes are saved
    hostViewController?.markEditorDirty(false)
    unblockUserInteraction()
  }
}
