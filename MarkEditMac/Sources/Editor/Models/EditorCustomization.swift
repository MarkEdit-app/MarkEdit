//
//  EditorCustomization.swift
//  MarkEditMac
//
//  Created by cyan on 2/24/23.
//

import Foundation
import MarkEditKit

/**
 Style sheet and script to change the appearance and behavior of the editor.

 Files are located at ~/Library/Containers/app.cyan.markedit/Data/Documents/
 */
final class EditorCustomization {
  enum FileType {
    case style
    case script

    var tagName: String {
      switch self {
      case .style: return "style"
      case .script: return "script"
      }
    }

    var pathExtension: String {
      switch self {
      case .style: return "css"
      case .script: return "js"
      }
    }
  }

  static let style = EditorCustomization(fileType: .style)
  static let script = EditorCustomization(fileType: .script)

  var contents: String {
    guard let fileURL else {
      return ""
    }

    guard let contents = (try? Data(contentsOf: fileURL))?.toString() else {
      return ""
    }

    return "<\(fileType.tagName)>\n\(contents)\n</\(fileType.tagName)>"
  }

  func createFile() {
    guard let fileURL else {
      return Logger.assertFail("Missing fileURL to proceed")
    }

    guard !FileManager.default.fileExists(atPath: fileURL.path) else {
      return
    }

    try? "".toData()?.write(to: fileURL)
  }

  // MARK: - Private

  private let fileType: FileType

  private var fileURL: URL? {
    FileManager.default.urls(
      for: .documentDirectory,
      in: .userDomainMask
    )
    .first?.appendingPathComponent("editor.\(fileType.pathExtension)")
  }

  private init(fileType: FileType) {
    self.fileType = fileType
  }
}
