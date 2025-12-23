//
//  URL+Extension.swift
//
//  Created by cyan on 12/23/25.
//

import Foundation

public extension URL {
  static var standardDirectories: [String: String] {
    [
      "home": Self.homeDirectory,
      "documents": Self.documentsDirectory,
      "library": Self.libraryDirectory,
      "caches": Self.cachesDirectory,
      "temporary": Self.temporaryDirectory,
    ].mapValues {
      $0.path(percentEncoded: false)
    }
  }
}
