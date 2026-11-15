//
//  EditorDocumentSaveTests.swift
//
//  Created by cyan on 10/21/26.
//

import AppKit
import MarkEditCore
import UniformTypeIdentifiers
import WebKit
import XCTest
@testable import MarkEdit

extension EditorDocumentTests {
  func testImportedTextTypeDeclarations() throws {
    let declarations = try XCTUnwrap(
      Bundle.main.object(forInfoDictionaryKey: "UTImportedTypeDeclarations") as? [[String: Any]]
    )

    for (identifier, fileExtension) in [
      ("com.mdxjs.mdx", "mdx"),
      ("org.tug.tex", "tex"),
      ("org.tug.ltx", "ltx"),
    ] {
      let declaration = try XCTUnwrap(declarations.first { $0["UTTypeIdentifier"] as? String == identifier })
      let tags = try XCTUnwrap(declaration["UTTypeTagSpecification"] as? [String: Any])
      XCTAssertEqual(tags["public.filename-extension"] as? [String], [fileExtension])

      let conformance = try XCTUnwrap(declaration["UTTypeConformsTo"] as? [String])
      XCTAssertTrue(conformance.contains("public.plain-text"))

      let type = try XCTUnwrap(UTType(identifier))
      XCTAssertTrue(type.isDeclared)
      XCTAssertTrue(type.conforms(to: .plainText))
      XCTAssertEqual(type.preferredFilenameExtension, fileExtension)

      let resolvedType = try XCTUnwrap(UTType(filenameExtension: fileExtension))
      XCTAssertFalse(resolvedType.isDynamic)
      XCTAssertTrue(resolvedType.conforms(to: .plainText))
    }

    let tex = try XCTUnwrap(UTType("org.tug.tex"))
    let latex = try XCTUnwrap(UTType("org.tug.ltx"))
    XCTAssertTrue(latex.conforms(to: tex))
  }

  func testMDXQuickLookEligibility() throws {
    let pluginsURL = try XCTUnwrap(Bundle.main.builtInPlugInsURL)
    let bundle = try XCTUnwrap(Bundle(url: pluginsURL.appending(path: "QuickLookExtension.appex")))
    let configuration = try XCTUnwrap(bundle.object(forInfoDictionaryKey: "NSExtension") as? [String: Any])
    let attributes = try XCTUnwrap(configuration["NSExtensionAttributes"] as? [String: Any])
    let identifiers = try XCTUnwrap(attributes["QLSupportedContentTypes"] as? [String])
    let mdx = try XCTUnwrap(UTType("com.mdxjs.mdx"))
    XCTAssertTrue(identifiers.compactMap { UTType($0) }.contains { mdx.conforms(to: $0) })
  }

  func testSavePreservesExistingTextFilename() async throws {
    let directory = ApplicationEnvironment.documentsDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let controller = NSDocumentController.shared
    let fileExtensions = [
      "md", "markdown", "mdown", "mdwn", "mkdn", "mkd", "mdoc", "mdtext", "mdtxt",
      "mdx", "MDX", "txt", "text", "mmd", "mermaid", "tex", "ltx", "markedit-unknown", "",
    ]

    for fileExtension in fileExtensions {
      let basename = UUID().uuidString
      let filename = fileExtension.isEmpty ? basename : "\(basename).\(fileExtension)"
      let url = directory.appending(path: filename)
      let data = Data("Original text\n".utf8)
      try data.write(to: url)

      let (openedDocument, _) = try await controller.openDocument(withContentsOf: url, display: false)
      let document = try XCTUnwrap(openedDocument as? EditorDocument)
      defer {
        document.isTerminating = true
        document.close()
        controller.removeDocument(document)
      }

      try await Self.waitUntilLoaded(document, data: data)
      document.stringValue = "Updated text\n"
      document.updateChangeCount(.changeDone)

      if fileExtension == "txt" {
        try data.write(to: url, options: .atomic)
      }

      let date = try XCTUnwrap(document.fileModificationDate).addingTimeInterval(-60)
      try FileManager.default.setAttributes([.modificationDate: date], ofItemAtPath: url.path)

      let completed = expectation(description: "Save completes for .\(fileExtension)")
      let delegate = SaveDelegate { savedDocument, success in
        XCTAssertIdentical(savedDocument, document)
        XCTAssertTrue(success)
        completed.fulfill()
      }

      // An explicit save(to:) bypasses AppKit's filename selection for ordinary Save
      document.save(
        withDelegate: delegate,
        didSave: #selector(SaveDelegate.document(_:didSave:contextInfo:)),
        contextInfo: nil
      )

      await fulfillment(of: [completed], timeout: 10)
      withExtendedLifetime(delegate) {}

      XCTAssertEqual(document.fileURL, url)
      XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
      XCTAssertEqual(try Data(contentsOf: url), Data("Updated text\n".utf8))

      document.stringValue = "Autosaved text\n"
      document.updateChangeCount(.changeDone)
      try await document.autosave(withImplicitCancellability: false)
      XCTAssertEqual(document.fileURL, url)
      XCTAssertEqual(try Data(contentsOf: url), Data("Autosaved text\n".utf8))
    }
  }

  func testAutosaveCompletesDuringCoordinatedFileAccess() async throws {
    let directory = ApplicationEnvironment.documentsDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let url = directory.appending(path: "document.txt")
    let data = Data("Original text\n".utf8)
    try data.write(to: url)
    let document = try EditorDocument(contentsOf: url, ofType: "public.plain-text")
    defer {
      document.isTerminating = true
      document.close()
    }

    try await Self.waitUntilLoaded(document, data: data)
    document.stringValue = "Autosaved text\n"
    document.updateChangeCount(.changeDone)
    XCTAssertFalse(document.isOutdated)

    let adjustedDate = try XCTUnwrap(document.fileModificationDate).addingTimeInterval(-60)
    let saved = expectation(description: "Autosave completes")
    let released = expectation(description: "Coordinated file access is released")
    document.presentedItemOperationQueue.addOperation {
      let relinquishToWriter = document.relinquishPresentedItem(toWriter:)
      relinquishToWriter { reacquire in
        do {
          try FileManager.default.setAttributes([.modificationDate: adjustedDate], ofItemAtPath: url.path)
        } catch {
          XCTFail("Failed to adjust the timestamp: \(error)")
        }

        let completed = DispatchSemaphore(value: 0)
        // Release independently of the main thread so a stalled autosave can finish and be cleaned up
        DispatchQueue.global().async {
          if completed.wait(timeout: .now() + 3) == .timedOut {
            XCTFail("Autosave did not finish inside coordinated file access")
          }

          reacquire?()
          released.fulfill()
        }

        document.savePresentedItemChanges { error in
          XCTAssertNil(error)
          completed.signal()
          saved.fulfill()
        }
      }
    }

    await fulfillment(of: [released, saved], timeout: 10)
    XCTAssertEqual(try Data(contentsOf: url), Data("Autosaved text\n".utf8))
    XCTAssertEqual(document.fileData, Data("Autosaved text\n".utf8))
  }

  func testTimestampOnlyChangesPreserveEditsAndAllowSaving() async throws {
    for autosaving in [false, true] {
      for offset in [-60.0, 60.0] {
        try await withExternalChangeDocument { document, url in
          let date = try XCTUnwrap(document.fileModificationDate).addingTimeInterval(offset)
          try FileManager.default.setAttributes([.modificationDate: date], ofItemAtPath: url.path)
          document.stringValue = "Saved B\n"
          document.updateChangeCount(.changeDone)

          if autosaving {
            try await document.autosave(withImplicitCancellability: false)
          } else {
            try await document.save(to: url, ofType: "public.plain-text", for: .saveOperation)
          }

          XCTAssertEqual(try Data(contentsOf: url), Data("Saved B\n".utf8))
          XCTAssertEqual(document.fileData, Data("Saved B\n".utf8))
          XCTAssertEqual(document.fileModificationDate, try modificationDate(at: url))

          document.stringValue = "Unsaved C\n"
          document.isOutdated = autosaving
          document.updateChangeCount(.changeDone)

          let touched = try XCTUnwrap(document.fileModificationDate).addingTimeInterval(offset)
          try FileManager.default.setAttributes([.modificationDate: touched], ofItemAtPath: url.path)
          await notifyExternalChange(document)

          XCTAssertEqual(document.stringValue, "Unsaved C\n")
          XCTAssertEqual(document.isOutdated, autosaving)
          XCTAssertTrue(document.isDocumentEdited)
          XCTAssertFalse(document.hasBeenReverted)
          XCTAssertEqual(document.fileData, Data("Saved B\n".utf8))
          XCTAssertEqual(document.fileModificationDate, try modificationDate(at: url))
        }
      }
    }
  }

  func testSaveAsKeepsNewFileContentsDuringOldFileNotification() async throws {
    try await withExternalChangeDocument { document, url in
      let date = try XCTUnwrap(document.fileModificationDate).addingTimeInterval(60)
      try FileManager.default.setAttributes([.modificationDate: date], ofItemAtPath: url.path)

      let text = String(repeating: "B", count: 1_048_576)
      let data = Data(text.utf8)
      document.stringValue = text
      document.updateChangeCount(.changeDone)

      let destination = url.deletingLastPathComponent().appending(path: "saved-as.txt")
      let saved = expectation(description: "Save As completes")
      document.save(to: destination, ofType: "public.plain-text", for: .saveAsOperation) { error in
        XCTAssertNil(error)
        saved.fulfill()
      }

      document.presentedItemDidChange()
      document.updateChangeCount(.changeDone)

      // Exercise queued notifications while save finalization is delayed by work on main
      let waitForWriting = {
        let deadline = Date().addingTimeInterval(3)
        let pause = DispatchSemaphore(value: 0)
        while document.fileData != data, Date() < deadline {
          _ = pause.wait(timeout: .now() + 0.001)
        }
        _ = document.fileURL
      }

      waitForWriting()
      await fulfillment(of: [saved], timeout: 5)
      await notifyExternalChange(document)
      let settled = expectation(description: "Queued read publication settles")
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { settled.fulfill() }

      await fulfillment(of: [settled], timeout: 2)
      try await Self.waitUntilLoaded(document, data: data)

      XCTAssertEqual(document.fileURL, destination)
      XCTAssertEqual(try Data(contentsOf: destination), data)
      XCTAssertEqual(document.stringValue, text)
      XCTAssertEqual(try String(contentsOf: url, encoding: .utf8), "Original text\n")
    }
  }

  func testTerminationWritePublishesSavedBytes() async throws {
    try await withExternalChangeDocument { document, url in
      document.stringValue = "Last edits\n"
      document.updateChangeCount(.changeDone)
      document.isTerminating = true
      try await document.autosave(withImplicitCancellability: false)

      XCTAssertEqual(document.fileData, Data("Last edits\n".utf8))
      XCTAssertEqual(try Data(contentsOf: url), document.fileData)
    }
  }

  func testRealExternalChangesStillRejectSaving() async throws {
    for autosaving in [false, true] {
      try await withExternalChangeDocument { document, url in
        let external = Data("External contents\n".utf8)
        try external.write(to: url, options: .atomic)
        let date = try XCTUnwrap(document.fileModificationDate).addingTimeInterval(-60)
        try FileManager.default.setAttributes([.modificationDate: date], ofItemAtPath: url.path)
        document.stringValue = "Unsaved local text\n"
        document.updateChangeCount(.changeDone)
        await notifyExternalChange(document)

        do {
          if autosaving {
            try await document.autosave(withImplicitCancellability: false)
          } else {
            try await document.save(to: url, ofType: "public.plain-text", for: .saveOperation)
          }

          XCTFail("A genuine external change must not be overwritten")
        } catch {
          XCTAssertEqual((error as NSError).code, 67000)
          document.willNotPresentError(error)
        }

        XCTAssertEqual(try Data(contentsOf: url), external)
        XCTAssertEqual(document.stringValue, "Unsaved local text\n")
        XCTAssertTrue(document.isDocumentEdited)
        XCTAssertEqual(document.fileData, Data("Original text\n".utf8))
      }
    }
  }

  func testMatchingExternalTextDoesNotResetEditor() async throws {
    try await withExternalChangeDocument { document, url in
      let data = Data("Matching text\n".utf8)
      document.stringValue = "Matching text\n"
      document.updateChangeCount(.changeDone)

      try data.write(to: url)
      let date = try XCTUnwrap(document.fileModificationDate).addingTimeInterval(60)
      try FileManager.default.setAttributes([.modificationDate: date], ofItemAtPath: url.path)
      await notifyExternalChange(document)

      XCTAssertFalse(document.hasBeenReverted)
      XCTAssertFalse(document.isDocumentEdited)
      XCTAssertEqual(document.fileData, data)

      let external = Data("Different external text\n".utf8)
      try external.write(to: url)
      try FileManager.default.setAttributes([.modificationDate: date.addingTimeInterval(60)], ofItemAtPath: url.path)
      document.presentedItemDidChange()

      try await Self.waitUntilLoaded(document, data: external)
      XCTAssertEqual(document.stringValue, "Different external text\n")
    }
  }

  func testExportKeepsOriginalByteCacheAndDate() async throws {
    try await withExternalChangeDocument { document, url in
      let date = try XCTUnwrap(document.fileModificationDate)
      try FileManager.default.setAttributes([.modificationDate: date.addingTimeInterval(60)], ofItemAtPath: url.path)
      document.stringValue = "Exported text\n"
      document.updateChangeCount(.changeDone)

      let exported = url.deletingLastPathComponent().appending(path: "export.txt")
      try await document.save(to: exported, ofType: "public.plain-text", for: .saveToOperation)

      XCTAssertEqual(document.fileData, Data("Original text\n".utf8))
      XCTAssertEqual(document.fileModificationDate, date)
      XCTAssertEqual(try String(contentsOf: exported, encoding: .utf8), "Exported text\n")
      XCTAssertEqual(try String(contentsOf: url, encoding: .utf8), "Original text\n")
    }
  }

  func testRecoveryBytesAreNotAnOriginalFileBaseline() async throws {
    try await withExternalChangeDocument { original, url in
      original.isTerminating = true
      original.close()

      let recoveryURL = url.deletingLastPathComponent().appending(path: "recovery.txt")
      let recovered = Data("Recovered edits\n".utf8)
      try recovered.write(to: recoveryURL)
      let document = try EditorDocument(for: url, withContentsOf: recoveryURL, ofType: "public.plain-text")
      NSFileCoordinator.removeFilePresenter(document)

      defer {
        document.isTerminating = true
        document.updateChangeCount(.changeCleared)
        document.close()
      }

      try await Self.waitUntilLoaded(document, data: recovered)
      document.updateChangeCount(.changeDone)
      let date = try XCTUnwrap(document.fileModificationDate)
      try FileManager.default.setAttributes([.modificationDate: date.addingTimeInterval(60)], ofItemAtPath: url.path)

      await notifyExternalChange(document)
      XCTAssertEqual(document.stringValue, "Recovered edits\n")
      XCTAssertEqual(document.fileModificationDate, date)
      XCTAssertTrue(document.isDocumentEdited)
      XCTAssertEqual(try Data(contentsOf: recoveryURL), recovered)

      try await document.save(to: url, ofType: "public.plain-text", for: .saveAsOperation)
      XCTAssertNil(document.autosavedContentsFileURL)
      document.stringValue = "Newer edits\n"
      document.updateChangeCount(.changeDone)

      let savedDate = try XCTUnwrap(document.fileModificationDate)
      try FileManager.default.setAttributes([.modificationDate: savedDate.addingTimeInterval(-60)], ofItemAtPath: url.path)

      try await document.save(to: url, ofType: "public.plain-text", for: .saveOperation)
      XCTAssertEqual(document.fileData, Data("Newer edits\n".utf8))
      XCTAssertEqual(try Data(contentsOf: url), document.fileData)
    }
  }

  private func modificationDate(at url: URL) throws -> Date {
    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
    return try XCTUnwrap(attributes[.modificationDate] as? Date)
  }

  private func notifyExternalChange(_ document: EditorDocument) async {
    await withCheckedContinuation { continuation in
      document.presentedItemDidChange()
      DispatchQueue.main.async { continuation.resume() }
    }
  }

  private func withExternalChangeDocument(action: (EditorDocument, URL) async throws -> Void) async throws {
    let directory = ApplicationEnvironment.documentsDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let url = directory.appending(path: "external.txt")
    let data = Data("Original text\n".utf8)
    try data.write(to: url)
    let document = try EditorDocument(contentsOf: url, ofType: "public.plain-text")
    NSFileCoordinator.removeFilePresenter(document)

    defer {
      document.isTerminating = true
      document.isOutdated = false
      document.updateChangeCount(.changeCleared)
      document.close()
    }

    try await Self.waitUntilLoaded(document, data: data)
    try await action(document, url)
  }

  func testPreferredExtensionOnlyRecognizesOutputTypes() {
    for fileExtension in NewFilenameExtension.allCases {
      XCTAssertEqual(NewFilenameExtension.preferredExtension(for: fileExtension.exportedType), fileExtension)
    }

    for typeName in ["public.plain-text", "net.daringfireball.markdown", "com.mdxjs.mdx", "org.textbundle.package", "unknown", ""] {
      XCTAssertNil(NewFilenameExtension.preferredExtension(for: typeName))
    }
  }

  func testFailedTextSynchronizationKeepsOutdatedFlag() async throws {
    try await withSynchronizationEditor { document, editor in
      _ = try await editor.webView.evaluateJavaScript("""
      window.webModules.core.getEditorText = () => { throw new Error("Test retrieval failure"); };
      void 0;
      """)

      document.isOutdated = true
      await withCheckedContinuation { continuation in
        document.updateContent { continuation.resume() }
      }

      XCTAssertTrue(document.isOutdated)
      XCTAssertEqual(document.stringValue, "Original text\n")
    }
  }

  func testEditDuringTextSynchronizationKeepsOutdatedFlag() async throws {
    try await withSynchronizationEditor { document, editor in
      _ = try await editor.webView.evaluateJavaScript("""
      const getText = window.webModules.core.getEditorText;
      window.webModules.core.getEditorText = () => {
        const text = getText();
        window.editor.dispatch({ changes: { from: 0, insert: "Newer " } });
        return text;
      };
      void 0;
      """)

      document.stringValue = "Previous snapshot\n"
      document.isOutdated = true
      await withCheckedContinuation { continuation in
        document.updateContent { continuation.resume() }
      }

      XCTAssertTrue(document.isOutdated)
      XCTAssertEqual(document.stringValue, "Original text\n")
    }
  }

  private func withSynchronizationEditor(
    action: (EditorDocument, EditorViewController) async throws -> Void
  ) async throws {
    let keepsWindows = AppPreferences.General.quitAlwaysKeepsWindows
    AppPreferences.General.quitAlwaysKeepsWindows = false
    defer { AppPreferences.General.quitAlwaysKeepsWindows = keepsWindows }

    let document = try EditorDocument(type: "public.plain-text")
    document.stringValue = "Original text\n"
    defer {
      document.isTerminating = true
      document.updateChangeCount(.changeCleared)
      document.close()
    }

    document.makeWindowControllers()
    let editor = try XCTUnwrap(document.windowControllers.first?.contentViewController as? EditorViewController)
    await editor.waitUntilLoaded()
    await editor.waitUntilEditorReset()

    XCTAssertTrue(editor.hasFinishedLoading)
    XCTAssertEqual(editor.pendingResetCount, 0)
    try await action(document, editor)
  }

  func testFilenameExtensionPrecedence() throws {
    let document = try EditorDocument(type: "public.plain-text")
    let originalDefault = AppPreferences.General.newFilenameExtension
    defer { AppPreferences.General.newFilenameExtension = originalDefault }

    let dynamicType = try XCTUnwrap(UTType(filenameExtension: "markedit-test-\(UUID().uuidString)"))
    XCTAssertTrue(dynamicType.isDynamic)

    let fallbackTypes = ["public.plain-text", "com.mdxjs.mdx", dynamicType.identifier, "unknown", ""]
    let locations: [(URL?, String?)] = [
      (nil, nil),
      (ApplicationEnvironment.documentsDirectory.appending(path: "existing.MDX"), "MDX"),
      (ApplicationEnvironment.documentsDirectory.appending(path: "extensionless"), ""),
    ]

    let operations: [NSDocument.SaveOperationType] = [
      .saveOperation, .autosaveInPlaceOperation, .saveAsOperation, .saveToOperation,
      .autosaveElsewhereOperation, .autosaveAsOperation,
    ]

    for defaultExtension in NewFilenameExtension.allCases {
      AppPreferences.General.newFilenameExtension = defaultExtension
      for (url, existingExtension) in locations {
        document.fileURL = url
        let expectedExtensions = NewFilenameExtension.allCases.map { ($0.exportedType, $0.rawValue) }
          + [("org.textbundle.package", "textbundle")]
          + fallbackTypes.map { ($0, existingExtension ?? defaultExtension.rawValue) }

        for (typeName, expectedExtension) in expectedExtensions {
          for operation in operations {
            XCTAssertEqual(
              document.fileNameExtension(forType: typeName, saveOperation: operation),
              expectedExtension,
              "Type: \(typeName), operation: \(operation.rawValue), URL: \(String(describing: url)), default: \(defaultExtension)"
            )
          }
        }
      }
    }
  }
}

@MainActor
private final class SaveDelegate: NSObject {
  let completion: (NSDocument, Bool) -> Void

  init(completion: @escaping (NSDocument, Bool) -> Void) {
    self.completion = completion
  }

  @objc func document(_ document: NSDocument, didSave success: Bool, contextInfo: UnsafeMutableRawPointer?) {
    completion(document, success)
  }
}
