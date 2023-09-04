//
//  EditorCustomization.swift
//  MarkEditMac
//
//  Created by cyan on 2/24/23.
//

import Foundation
import MarkEditKit

/**
 Style sheet, script and config file to change the appearance and behavior of the editor.

 Files are located at ~/Library/Containers/app.cyan.markedit/Data/Documents/
 */
final class EditorCustomization {
  enum FileType {
    case style
    case script
    case pandoc

    var tagName: String? {
      switch self {
      case .style: return "style"
      case .script: return "script"
      case .pandoc: return nil
      }
    }

    var fileName: String {
      switch self {
      case .style: return "editor.css"
      case .script: return "editor.js"
      case .pandoc: return "pandoc.yaml"
      }
    }
  }

  static let style = EditorCustomization(fileType: .style)
  static let script = EditorCustomization(fileType: .script)
  static let pandoc = EditorCustomization(fileType: .pandoc)

  static func createFiles() {
    style.createFile()
    script.createFile()
    pandoc.createFile("from: gfm\nstandalone: true\npdf-engine: context\n")
  }

  var fileURL: URL? {
    FileManager.default.urls(
      for: .documentDirectory,
      in: .userDomainMask
    )
    .first?.appending(path: fileType.fileName, directoryHint: .notDirectory)
  }

  var contents: String {
    guard let fileURL else {
      return ""
    }

    guard let contents = (try? Data(contentsOf: fileURL))?.toString() else {
      return ""
    }

    if let tagName = fileType.tagName {
      return "<\(tagName)>\n\(contents)\n</\(tagName)>"
    } else {
      return contents
    }
  }

  // MARK: - Private

  private let fileType: FileType

  private init(fileType: FileType) {
    self.fileType = fileType
  }

  private func createFile(_ contents: String = "") {
    guard let fileURL else {
      return Logger.assertFail("Missing fileURL to proceed")
    }

    guard !FileManager.default.fileExists(atPath: fileURL.path) else {
      return
    }

    try? contents.toData()?.write(to: fileURL)
  }
}
