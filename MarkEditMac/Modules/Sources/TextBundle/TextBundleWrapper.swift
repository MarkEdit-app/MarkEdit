//
//  TextBundleWrapper.swift
//
//  Created by cyan on 3/23/23.
//

import Foundation

/**
 Lightweight wrapper for [TextBundle](https://textbundle.org/).

 Typical structure:
  - assets/
  - info.json
  - text.markdown

 FileWrapper parsing is learned from: https://github.com/shinyfrog/TextBundle.
 */
public struct TextBundleWrapper {
  public let data: Data
  public let info: TextBundleInfo

  private let textFileName: String
  private let assetsFileWrapper: FileWrapper?

  public init(fileWrapper: FileWrapper) throws {
    guard let textFileWrapper = fileWrapper.fileWrappers?[fileWrapper.textFileName] else {
      throw TextBundleError.invalidBundle
    }

    guard let textFileData = textFileWrapper.regularFileContents else {
      throw TextBundleError.invalidBundle
    }

    guard let infoFileWrapper = fileWrapper.fileWrappers?[Keys.infoFileName] else {
      throw TextBundleError.invalidBundle
    }

    guard let infoFileData = infoFileWrapper.regularFileContents else {
      throw TextBundleError.invalidBundle
    }

    data = textFileData
    info = try JSONDecoder().decode(TextBundleInfo.self, from: infoFileData)

    textFileName = fileWrapper.textFileName
    assetsFileWrapper = fileWrapper.fileWrappers?[Keys.assetsFileName]
  }

  public func textFilePath(baseURL: URL) -> String? {
    baseURL.appendingPathComponent(textFileName).path
  }

  public func fileWrapper(with textFileData: Data) throws -> FileWrapper {
    let fileWrapper = FileWrapper(directoryWithFileWrappers: [:])
    fileWrapper.addRegularFile(withContents: textFileData, preferredFilename: textFileName)

    let jsonEncoder = JSONEncoder()
    jsonEncoder.outputFormatting = [.sortedKeys, .prettyPrinted]

    let infoFileData = try jsonEncoder.encode(info)
    fileWrapper.addRegularFile(withContents: infoFileData, preferredFilename: Keys.infoFileName)

    if let assetsFileWrapper {
      fileWrapper.addFileWrapper(assetsFileWrapper)
    }

    return fileWrapper
  }
}
