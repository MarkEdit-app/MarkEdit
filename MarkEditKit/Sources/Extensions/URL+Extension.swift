//
//  URL+Extension.swift
//
//  Created by cyan on 1/15/23.
//

import Foundation
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

    if suggestedFileType?.conforms(to: .text) ?? true {
      return false
    }

    return true
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
}

private let textFileExtensions = Set(
  [
    "md",
    "markdown",
    "mdown",
    "mdwn",
    "mkdn",
    "mkd",
    "mdoc",
    "mdtext",
    "mdtxt",
    "textbundle",
    "txt",
  ]
)
