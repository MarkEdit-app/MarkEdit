//
//  URL+Extension.swift
//
//  Created by cyan on 1/15/23.
//

import Foundation
import MarkEditCore
import UniformTypeIdentifiers

public extension URL {
  var localizedName: String {
    (try? resourceValues(forKeys: Set([.localizedNameKey])))?.name ?? lastPathComponent
  }

  var resolvingSymbolicLink: URL {
    guard isSymbolicLink else {
      return self
    }

    do {
      let resolvedPath = try FileManager.default.destinationOfSymbolicLink(atPath: path)
      return URL(filePath: resolvedPath)
    } catch {
      return self
    }
  }

  var isBinaryFile: Bool {
    if textFileExtensions.contains(pathExtension.lowercased()) {
      return false
    }

    let type = suggestedFileType
    if type?.conforms(to: .text) == true {
      return false
    }

    let isTypeless = pathExtension.isEmpty && (type == nil || type == .data || type?.isDynamic == true)
    if isTypeless, let binarySample {
      return binarySample.isProbablyBinary
    }

    return type != nil
  }

  var isImageFile: Bool {
    guard let type = UTType(filenameExtension: pathExtension) else {
      return false
    }

    return type.conforms(to: .image)
  }

  /// POSIX relative path from directory `base` to this URL.
  ///
  /// Returns `"."` when the two URLs refer to the same path. Symlinks are
  /// resolved before comparison, so paths under `/var` and `/private/var`
  /// reduce consistently. `.` / `..` segments are normalized away.
  func relativePath(from base: URL) -> String {
    let resolvedBase = base.resolvingSymlinksInPath().standardizedFileURL
    let resolvedTarget = resolvingSymlinksInPath().standardizedFileURL
    let baseParts = resolvedBase.pathComponents.filter { $0 != "/" }
    let targetParts = resolvedTarget.pathComponents.filter { $0 != "/" }

    // Skip the shared prefix, then climb out of `base` and descend into the target.
    var common = 0
    while common < baseParts.count, common < targetParts.count, baseParts[common] == targetParts[common] {
      common += 1
    }

    let ups = Array(repeating: "..", count: baseParts.count - common)
    let downs = Array(targetParts[common...])
    let segments = ups + downs
    return segments.isEmpty ? "." : segments.joined(separator: "/")
  }

  func replacingPathExtension(_ pathExtension: String) -> URL {
    deletingPathExtension().appendingPathExtension(pathExtension)
  }
}

// MARK: - Private

private extension URL {
  var isSymbolicLink: Bool {
    (try? resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) ?? false
  }

  var suggestedFileType: UTType? {
    if let associatedType = (try? resourceValues(forKeys: [.contentTypeKey]))?.contentType {
      return associatedType
    }

    return UTType(filenameExtension: pathExtension)
  }

  var binarySample: Data? {
    guard (try? resourceValues(forKeys: [.isRegularFileKey]))?.isRegularFile == true,
          let handle = try? FileHandle(forReadingFrom: self) else {
      return nil
    }

    defer { try? handle.close() }
    do {
      return try handle.read(upToCount: 512) ?? Data()
    } catch {
      return nil
    }
  }
}

private let textFileExtensions = Set(
  [
    // Markdown
    "md",
    "markdown",
    "mdown",
    "mdwn",
    "mkdn",
    "mkd",
    "mdoc",
    "mdtext",
    "mdtxt",
    "mdx",
    // TextBundle
    "textbundle",
    // Plain Text
    "txt",
    "text",
    // Structured Text
    "mmd",
    "mermaid",
    "tex",
    "ltx",
  ]
)
