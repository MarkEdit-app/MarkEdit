//
//  EditorFileSnapshots.swift
//
//  Created by cyan on 11/15/26.
//

import Foundation

struct EditorFileSnapshots: Sendable {
  var saved: Data?
  var pending: Data?
  var isWriting = false

  mutating func saveDidFinish(succeeded: Bool) {
    if succeeded, let pending {
      saved = pending
    }

    pending = nil
  }
}
