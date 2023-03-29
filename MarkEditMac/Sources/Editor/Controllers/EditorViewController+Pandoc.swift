//
//  EditorViewController+Pandoc.swift
//  MarkEditMac
//
//  Created by cyan on 1/21/23.
//

import AppKit
import MarkEditKit

extension EditorViewController {
  /// https://pandoc.org/
  func copyPandocCommand(document: EditorDocument, format: String) {
    guard let inputURL = document.textFileURL else {
      Logger.log(.error, "Failed to copy pandoc command")
      return
    }

    let configPath = EditorCustomization.pandoc.fileURL?.escapedFilePath ?? ""
    let outputPath = inputURL.replacingPathExtension(format).escapedFilePath

    let command = [
      "pandoc",
      inputURL.escapedFilePath,
      "-t \(format)",
      "-d \(configPath)",
      "-o \(outputPath)",
      "&& open -R \(outputPath)",
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
