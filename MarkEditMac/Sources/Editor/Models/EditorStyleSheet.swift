//
//  EditorStyleSheet.swift
//  MarkEditMac
//
//  Created by cyan on 2/24/23.
//

import Foundation
import MarkEditKit

/**
 Style sheet to change the appearance of the editor.

 The file is located at ~/Library/Containers/app.cyan.markedit/Data/Documents/editor.css
 */
final class EditorStyleSheet {
  static let shared = EditorStyleSheet()

  var contents: String {
    guard let fileURL else {
      return ""
    }

    guard let css = (try? Data(contentsOf: fileURL))?.toString() else {
      return ""
    }

    return "<style>\n\(css)\n</style>"
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

  private var fileURL: URL? {
    FileManager.default.urls(
      for: .documentDirectory,
      in: .userDomainMask
    )
    .first?.appendingPathComponent("editor.css")
  }

  private init() {}
}
