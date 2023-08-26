//
//  FileSize.swift
//
//  Created by cyan on 8/26/23.
//

import Foundation

enum FileSize {
  static func readableSize(of fileURL: URL?) -> String? {
    guard let filePath = fileURL?.path else {
      return nil
    }

    guard let attributes = try? FileManager.default.attributesOfItem(atPath: filePath) else {
      return nil
    }

    guard let fileSize = attributes[.size] as? Int64 else {
      return nil
    }

    return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
  }
}
