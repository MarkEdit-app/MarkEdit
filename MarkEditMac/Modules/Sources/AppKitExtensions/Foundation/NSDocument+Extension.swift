//
//  NSDocument+Extension.swift
//
//  Created by cyan on 1/21/23.
//

import AppKit

public extension NSDocument {
  var folderURL: URL? {
    fileURL?.deletingLastPathComponent()
  }

  /// Update the change count to exactly `undoDepth`.
  func updateChangeCount(undoDepth: Int) {
    updateChangeCount(.changeCleared)

    for _ in 0 ..< undoDepth {
      updateChangeCount(.changeDone)
    }
  }
}
