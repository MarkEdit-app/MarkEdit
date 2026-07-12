//
//  AppCustomization.swift
//  MarkEditMac
//
//  Created by cyan on 2/24/23.
//

import Foundation
import ExtensionCore
import MarkEditCore
import MarkEditKit

/**
 Style sheet, script and config files to change the appearance and behavior of the app.

 Files are located at ~/Library/Containers/app.cyan.markedit/Data/Documents/
 */
struct AppCustomization {
  enum FileType {
    case editorStyle
    case stylesDirectory
    case editorScript
    case scriptsDirectory
    case debugDirectory
    case pandoc
    case statisticsRules
    case settings
    case extensions

    var fileName: String {
      switch self {
      case .editorStyle: return "editor.css"
      case .stylesDirectory: return "styles"
      case .editorScript: return "editor.js"
      case .scriptsDirectory: return "scripts"
      case .debugDirectory: return "debug"
      case .pandoc: return "pandoc.yaml"
      case .statisticsRules: return "statistics-rules.json"
      case .settings: return "settings.json"
      case .extensions: return "extensions.json"
      }
    }

    var isDirectory: Bool {
      switch self {
      case .stylesDirectory, .scriptsDirectory, .debugDirectory: return true
      default: return false
      }
    }
  }

  static let editorStyle = Self(fileType: .editorStyle)
  static let stylesDirectory = Self(fileType: .stylesDirectory)
  static let editorScript = Self(fileType: .editorScript)
  static let scriptsDirectory = Self(fileType: .scriptsDirectory)
  static let debugDirectory = Self(fileType: .debugDirectory)
  static let pandoc = Self(fileType: .pandoc)
  static let statisticsRules = Self(fileType: .statisticsRules)
  static let settings = Self(fileType: .settings)
  static let extensions = Self(fileType: .extensions)

  static func createFiles() {
    editorStyle.createFile()
    stylesDirectory.createFile()
    editorScript.createFile()
    scriptsDirectory.createFile()
    debugDirectory.createFile()
    pandoc.createFile("from: gfm\nstandalone: true\npdf-engine: context\n")
    statisticsRules.createFile("[]")
    settings.createFile(AppRuntimeConfig.defaultContents)
    extensions.createFile(ExtensionConfig.defaultContents)
  }

  var fileURL: URL {
    URL.documentsDirectory.appending(
      path: fileType.fileName,
      directoryHint: fileType.isDirectory ? .isDirectory : .notDirectory
    ).resolvingSymbolicLink
  }

  var fileContents: String {
    createContents(url: fileURL) ?? ""
  }

  func styleContents() -> [String] {
    fileURL.sortedFiles(types: ["css"])
      .compactMap { createContents(url: $0.resolvingSymbolicLink) }
  }

  func contentsFrom(fileNames: [String]) -> [String] {
    fileNames
      .map { fileURL.appending(path: $0, directoryHint: .notDirectory).resolvingSymbolicLink }
      .compactMap { createContents(url: $0) }
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

    if fileType.isDirectory {
      try? FileManager.default.createDirectory(at: fileURL, withIntermediateDirectories: true)
    } else {
      try? contents.toData()?.write(to: fileURL)
    }

    return true
  }

  private func createContents(url: URL) -> String? {
    guard let contents = (try? Data(contentsOf: url))?.toString(), !contents.isEmpty else {
      return nil
    }

    switch fileType {
    case .editorScript, .scriptsDirectory:
      return EditorUserAsset.script(for: url, contents: contents)
    case .editorStyle, .stylesDirectory:
      return EditorUserAsset.style(for: url, contents: contents)
    default:
      return contents
    }
  }
}
