//
//  URL+Extension.swift
//
//  Created by cyan on 1/15/23.
//

import Foundation

public extension URL {
  var localizedName: String {
    (try? resourceValues(forKeys: Set([.localizedNameKey])))?.name ?? lastPathComponent
  }

  func replacingPathExtension(_ pathExtension: String) -> URL {
    deletingPathExtension().appendingPathExtension(pathExtension)
  }
}
