//
//  EditorDocumentSaveTests.swift
//
//  Created by cyan on 10/21/26.
//

import AppKit
import MarkEditCore
import XCTest
@testable import MarkEdit

extension EditorDocumentTests {
  func testSavePreservesExistingTextFilename() async throws {
    let directory = ApplicationEnvironment.documentsDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let controller = NSDocumentController.shared
    for fileExtension in ["md", "markdown", "txt", "mmd", "mermaid"] {
      let url = directory.appending(path: "existing-\(fileExtension).\(fileExtension)")
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
