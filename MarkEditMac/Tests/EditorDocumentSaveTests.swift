//
//  EditorDocumentSaveTests.swift
//
//  Created by cyan on 10/21/26.
//

import AppKit
import MarkEditCore
import UniformTypeIdentifiers
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

    let saved = expectation(description: "Autosave completes")
    let released = expectation(description: "Coordinated file access is released")
    document.presentedItemOperationQueue.addOperation {
      let relinquishToWriter = document.relinquishPresentedItem(toWriter:)
      relinquishToWriter { reacquire in
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
  }

  func testPreferredExtensionOnlyRecognizesOutputTypes() {
    for fileExtension in NewFilenameExtension.allCases {
      XCTAssertEqual(NewFilenameExtension.preferredExtension(for: fileExtension.exportedType), fileExtension)
    }

    for typeName in ["public.plain-text", "net.daringfireball.markdown", "com.mdxjs.mdx", "org.textbundle.package", "unknown", ""] {
      XCTAssertNil(NewFilenameExtension.preferredExtension(for: typeName))
    }
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
