//
//  AppCustomization.swift
//  MarkEditMac
//
//  Created by cyan on 2/24/23.
//

import Foundation
import MarkEditKit

/**
 Style sheet, script and config files to change the appearance and behavior of the app.

 Files are located at ~/Library/Containers/app.cyan.markedit/Data/Documents/
 */
struct AppCustomization {
  enum FileType {
    case style
    case script
    case pandoc
    case settings

    var tagName: String? {
      switch self {
      case .style: return "style"
      case .script: return "script"
      case .pandoc, .settings: return nil
      }
    }

    var fileName: String {
      switch self {
      case .style: return "editor.css"
      case .script: return "editor.js"
      case .pandoc: return "pandoc.yaml"
      case .settings: return "settings.json"
      }
    }
  }

  static let style = Self(fileType: .style)
  static let script = Self(fileType: .script)
  static let pandoc = Self(fileType: .pandoc)
  static let settings = Self(fileType: .settings)

  static func createFiles() {
    style.createFile()
    script.createFile()
    pandoc.createFile("from: gfm\nstandalone: true\npdf-engine: context\n")
    settings.createFile(AppRuntimeConfig.defaultContents)
  }

  var fileURL: URL {
    URL.documentsDirectory.appending(path: fileType.fileName, directoryHint: .notDirectory)
  }

  var fileData: Data? {
    try? Data(contentsOf: fileURL.resolvingSymbolicLink)
  }

  var contents: String {
    guard let contents = fileData?.toString() else {
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

  @discardableResult
  private func createFile(_ contents: String = "") -> Bool {
    guard !FileManager.default.fileExists(atPath: fileURL.path) else {
      return false
    }

    try? contents.toData()?.write(to: fileURL)
    return true
  }
}
