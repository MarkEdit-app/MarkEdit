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

  func markContentDirty(_ isDirty: Bool) {
    // The undo stack is implemented in CoreEditor entirely,
    // there are only two meaningful change count values: 0 (saved) or 1 (dirty).
    updateChangeCount(isDirty ? .changeDone : .changeCleared)
  }
}
