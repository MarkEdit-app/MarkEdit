//
//  DocumentBrowserViewController.swift
//  MarkEditiOS
//
//  Entry point — integrates with iOS Files app via UIDocumentBrowserViewController.
//

import UIKit
import UniformTypeIdentifiers

final class DocumentBrowserViewController: UIDocumentBrowserViewController {

  init() {
    // Explicitly declare the content types this browser opens.
    // Using the bare default init() without content types can produce a blank/dark
    // screen because UIDocumentBrowserViewController doesn't know what to display.
    let markdownType = UTType("net.daringfireball.markdown") ?? .plainText
    super.init(forOpeningContentTypes: [markdownType, .plainText])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // Diagnostic: a tinted background confirms this VC is rendering.
    // Swap to .systemBackground once the file browser UI is confirmed visible.
    view.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.15)

    delegate = self
    allowsDocumentCreation = true
    allowsPickingMultipleItems = false
    browserUserInterfaceStyle = .automatic
    view.tintColor = .systemBlue

    NSLog("[MarkEditiOS] DocumentBrowserViewController viewDidLoad — view.frame: %@", NSCoder.string(for: view.frame))
  }
}

// MARK: - UIDocumentBrowserViewControllerDelegate

extension DocumentBrowserViewController: UIDocumentBrowserViewControllerDelegate {

  /// User tapped "New Document" — create a temp .md file and hand it to the import handler.
  func documentBrowser(
    _ controller: UIDocumentBrowserViewController,
    didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void
  ) {
    let tempDir = FileManager.default.temporaryDirectory
    let tempURL = tempDir.appendingPathComponent("Untitled.md")

    do {
      try "".write(to: tempURL, atomically: true, encoding: .utf8)
      importHandler(tempURL, .move)
    } catch {
      importHandler(nil, .none)
    }
  }

  /// User picked an existing document.
  func documentBrowser(
    _ controller: UIDocumentBrowserViewController,
    didPickDocumentsAt documentURLs: [URL]
  ) {
    guard let url = documentURLs.first else { return }
    presentEditorForDocument(at: url)
  }

  /// System finished importing the newly-created document.
  func documentBrowser(
    _ controller: UIDocumentBrowserViewController,
    didImportDocumentAt sourceURL: URL,
    toDestinationURL destinationURL: URL
  ) {
    presentEditorForDocument(at: destinationURL)
  }

  /// Import failed.
  func documentBrowser(
    _ controller: UIDocumentBrowserViewController,
    failedToImportDocumentAt documentURL: URL,
    error: Error?
  ) {
    let alert = UIAlertController(
      title: "Could Not Open Document",
      message: error?.localizedDescription ?? "An unknown error occurred.",
      preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
  }
}

// MARK: - Private

private extension DocumentBrowserViewController {
  func presentEditorForDocument(at url: URL) {
    NSLog("[MarkEditiOS] DocumentBrowserViewController opening document: %@", url.lastPathComponent)
    let document = MarkEditDocument(fileURL: url)

    document.open { [weak self] success in
      guard let self, success else {
        NSLog("[MarkEditiOS] DocumentBrowserViewController failed to open document: %@", url.lastPathComponent)
        let alert = UIAlertController(
          title: "Could Not Open File",
          message: "The file could not be opened.",
          preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self?.present(alert, animated: true)
        return
      }

      NSLog("[MarkEditiOS] DocumentBrowserViewController presenting EditorViewController")
      let editorVC = EditorViewController(document: document)
      let nav = UINavigationController(rootViewController: editorVC)
      nav.modalPresentationStyle = .fullScreen
      self.present(nav, animated: true)
    }
  }
}
