//
//  FileDropTests.swift
//
//  Created by cyan on 5/6/26.
//

@testable import FileDrop
import MarkEditKit
import XCTest

final class FileDropTests: XCTestCase {

  // MARK: - MarkdownLink

  func testMarkdownLinkText() {
    XCTAssertEqual(
      MarkdownLink.formatted(label: "notes", target: "notes.md", isImage: false),
      "[notes](notes.md)"
    )
  }

  func testMarkdownLinkImage() {
    XCTAssertEqual(
      MarkdownLink.formatted(label: "photo.png", target: "assets/photo.png", isImage: true),
      "![photo.png](assets/photo.png)"
    )
  }

  func testMarkdownLinkEscapesBracketsInLabel() {
    XCTAssertEqual(
      MarkdownLink.formatted(label: "[draft]", target: "x.md", isImage: false),
      "[\\[draft\\]](x.md)"
    )
  }

  func testMarkdownLinkEncodesParensAndSpaces() {
    XCTAssertEqual(
      MarkdownLink.formatted(label: "f", target: "a (b) c.png", isImage: true),
      "![f](a%20%28b%29%20c.png)"
    )
  }

  func testMarkdownLinkPreservesPathSeparators() {
    XCTAssertEqual(
      MarkdownLink.formatted(label: "f", target: "a/b/c.png", isImage: true),
      "![f](a/b/c.png)"
    )
  }

  // MARK: - FileDropHandler

  func testFileDropHandlerSavedDocSameFolder() throws {
    let dir = try makeTempDir()
    defer { try? FileManager.default.removeItem(at: dir) }

    let docURL = dir.appending(path: "notes.md")
    let imageURL = dir.appending(path: "photo.png")
    try Data().write(to: imageURL)

    let result = FileDropHandler.handle(
      fileURL: imageURL,
      documentURL: docURL,
      documentType: nil
    )

    XCTAssertEqual(result, "![photo.png](photo.png)")
  }

  func testFileDropHandlerSavedDocSiblingFolder() throws {
    let dir = try makeTempDir()
    defer { try? FileManager.default.removeItem(at: dir) }

    let notes = dir.appending(path: "notes")
    let images = dir.appending(path: "images")
    try FileManager.default.createDirectory(at: notes, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: images, withIntermediateDirectories: true)

    let docURL = notes.appending(path: "doc.md")
    let imageURL = images.appending(path: "photo.png")
    try Data().write(to: imageURL)

    let result = FileDropHandler.handle(
      fileURL: imageURL,
      documentURL: docURL,
      documentType: nil
    )

    XCTAssertEqual(result, "![photo.png](../images/photo.png)")
  }

  func testFileDropHandlerUntitledUsesAbsolutePath() throws {
    let dir = try makeTempDir()
    defer { try? FileManager.default.removeItem(at: dir) }

    let imageURL = dir.appending(path: "photo.png")
    try Data().write(to: imageURL)

    let result = FileDropHandler.handle(
      fileURL: imageURL,
      documentURL: nil,
      documentType: nil
    )

    let expected = "![photo.png](\(MarkdownLink.encode(path: imageURL.resolvingSymlinksInPath().path(percentEncoded: false))))"
    XCTAssertEqual(result, expected)
  }

  func testFileDropHandlerTextBundleCopiesIntoAssets() throws {
    let dir = try makeTempDir()
    defer { try? FileManager.default.removeItem(at: dir) }

    let bundleURL = dir.appending(path: "doc.textbundle")
    try FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)

    let imageURL = dir.appending(path: "photo.png")
    try Data([0x89, 0x50, 0x4E, 0x47]).write(to: imageURL)

    let result = FileDropHandler.handle(
      fileURL: imageURL,
      documentURL: bundleURL,
      documentType: "org.textbundle.package"
    )

    XCTAssertEqual(result, "![photo.png](assets/photo.png)")

    let copiedURL = bundleURL.appending(path: "assets/photo.png")
    XCTAssertTrue(FileManager.default.fileExists(atPath: copiedURL.path(percentEncoded: false)))
  }

  func testFileDropHandlerTextBundleNamesCollidingFilesUniquely() throws {
    let dir = try makeTempDir()
    defer { try? FileManager.default.removeItem(at: dir) }

    let bundleURL = dir.appending(path: "doc.textbundle")
    let assetsURL = bundleURL.appending(path: "assets")
    try FileManager.default.createDirectory(at: assetsURL, withIntermediateDirectories: true)
    try Data().write(to: assetsURL.appending(path: "photo.png"))

    let imageURL = dir.appending(path: "photo.png")
    try Data().write(to: imageURL)

    let result = FileDropHandler.handle(
      fileURL: imageURL,
      documentURL: bundleURL,
      documentType: "org.textbundle.package"
    )

    XCTAssertEqual(result, "![photo.png](assets/photo-1.png)")
  }

  func testFileDropHandlerSavedDocSiblingSubtree() throws {
    // Verifies the ../sibling form when the document and target live in
    // different children of a common ancestor.
    let dir = try makeTempDir()
    defer { try? FileManager.default.removeItem(at: dir) }

    let docURL = dir.appending(path: "sub/notes.md")
    let imageURL = dir.appending(path: "other/photo.png")
    try FileManager.default.createDirectory(at: imageURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data().write(to: imageURL)

    let result = FileDropHandler.handle(
      fileURL: imageURL,
      documentURL: docURL,
      documentType: nil
    )

    XCTAssertEqual(result, "![photo.png](../other/photo.png)")
  }

  // MARK: - URL.relativePath(from:)

  func testRelativePathSamePath() {
    let url = URL(filePath: "/tmp/foo")
    XCTAssertEqual(url.relativePath(from: url), ".")
  }

  func testRelativePathChildOfBase() {
    let base = URL(filePath: "/tmp/notes")
    let target = URL(filePath: "/tmp/notes/sub/foo.png")
    XCTAssertEqual(target.relativePath(from: base), "sub/foo.png")
  }

  func testRelativePathSibling() {
    let base = URL(filePath: "/tmp/notes")
    let target = URL(filePath: "/tmp/photos/foo.png")
    XCTAssertEqual(target.relativePath(from: base), "../photos/foo.png")
  }

  func testRelativePathFromRoot() {
    let base = URL(filePath: "/")
    let target = URL(filePath: "/foo/bar.png")
    XCTAssertEqual(target.relativePath(from: base), "foo/bar.png")
  }

  func testRelativePathDifferentVolumesEmitsUpwardChain() {
    let base = URL(filePath: "/Users/me/notes")
    let target = URL(filePath: "/Volumes/Ext/foo.png")
    XCTAssertEqual(target.relativePath(from: base), "../../../Volumes/Ext/foo.png")
  }

  func testRelativePathNormalizesDotComponents() {
    let base = URL(filePath: "/tmp/notes/./")
    let target = URL(filePath: "/tmp/notes/sub/../foo.png")
    XCTAssertEqual(target.relativePath(from: base), "foo.png")
  }
}

// MARK: - Private

private extension FileDropTests {
  func makeTempDir() throws -> URL {
    // Resolve symlinks so paths produced under /var match /private/var on macOS.
    let url = FileManager.default.temporaryDirectory
      .resolvingSymlinksInPath()
      .appending(path: "FileDropTests-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
  }
}
