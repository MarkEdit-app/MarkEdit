//
//  EditorViewController+Pandoc.swift
//  MarkEditMac
//
//  Created by cyan on 1/21/23.
//

import AppKit
import MarkEditKit

extension EditorViewController {
  func copyPandocCommand(url: URL, format: String) {
    // https://pandoc.org/
    let command = [
      "pandoc",
      url.escapedFilePath,
      "-t \(format)",
      "-d \(EditorCustomization.pandoc.fileURL?.escapedFilePath ?? "")",
      "-o \(url.replacingPathExtension(format).escapedFilePath)",
      "&& open \(url.deletingLastPathComponent().escapedFilePath)",
    ].joined(separator: " ")

    NSPasteboard.general.overwrite(string: command)
    NSWorkspace.shared.openTerminal()
  }
}

// MARK: - Private

private extension URL {
  var escapedFilePath: String {
    path.replacingOccurrences(of: " ", with: "\\ ")
  }
}
