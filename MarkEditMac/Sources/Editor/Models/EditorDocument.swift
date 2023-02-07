//
//  EditorDocument.swift
//  MarkEditMac
//
//  Created by cyan on 12/12/22.

import AppKit
import MarkEditKit

/**
 Main document used to deal with markdown files.

 https://developer.apple.com/documentation/appkit/nsdocument
 */
final class EditorDocument: NSDocument {
  var fileData: Data?
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

  private weak var hostViewController: EditorViewController?

  override func makeWindowControllers() {
    let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
    let sceneIdentifier = NSStoryboard.SceneIdentifier("EditorWindowController")

    guard let windowController = storyboard.instantiateController(withIdentifier: sceneIdentifier) as? NSWindowController else {
      return
    }

    // Note hostViewController is a weak reference, it must be strongly retained first
    let contentVC = EditorReusePool.shared.dequeueViewController()
    windowController.contentViewController = contentVC

    hostViewController = contentVC
    hostViewController?.representedObject = self

    let hasOpenPanels = NSApplication.shared.hasOpenPanels
    NSApplication.shared.closeOpenPanels()

    // Return early, window creation in version browsing mode cannot be asynchronous
    guard !NSDocumentController.shared.documents.contains(where: { $0.isBrowsingVersions }) else {
      return addWindowController(windowController)
    }

    // Return early, the line number glitch happens only when there're open panels
    guard hasOpenPanels else {
      return addWindowController(windowController)
    }

    // Dirty trick, show the window later to wait CodeMirror finishes its initial layout,
    // the line number height is not initially correct because of the window animation,
    // we skip showing the window in makeWindowControllers and wait the final layout.
    DispatchQueue.afterDelay(seconds: 0.02) {
      self.hostViewController?.view.needsLayout = true
      self.addWindowController(windowController)
      self.showWindows()
    }
  }
}

// MARK: - Overridden

extension EditorDocument {
  override class var autosavesInPlace: Bool {
    true
  }

  override func canAsynchronouslyWrite(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType) -> Bool {
    true
  }

  override class func canConcurrentlyReadDocuments(ofType type: String) -> Bool {
    true
  }

  // MARK: - Reading and Writing

  override func read(from data: Data, ofType typeName: String) throws {
    let encoding = AppPreferences.General.defaultTextEncoding
    let newValue = encoding.decode(data: data) ?? data.toString() ?? ""
    guard stringValue != newValue else {
      return
    }

    fileData = data
    stringValue = newValue
    hostViewController?.representedObject = self
  }

  // We don't have a sync way to get the text, override save and autosave to do an async approach.
  //
  // Note that, by only overriding the "saveToURL" method can bring hang issues.
  override func save(_ sender: Any?) {
    Task {
      await saveAsynchronously {
        super.save(sender)
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
        if let modificationDate = try FileManager.default.attributesOfItem(atPath: fileURL.path)[.modificationDate] as? Date, modificationDate > (self.fileModificationDate ?? .distantPast) {
          try self.revert(toContentsOf: fileURL, ofType: fileType)
        }
      } catch {
        Logger.log(.error, error.localizedDescription)
      }
    }
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
