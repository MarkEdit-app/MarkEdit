//
//  NSSavePanel+Extension.swift
//
//  Created by cyan on 12/22/24.
//

import AppKit
import UniformTypeIdentifiers

public extension NSSavePanel {
  func enforceUniformType(_ type: UTType) {
    let otherFileTypesWereAllowed = allowsOtherFileTypes
    allowsOtherFileTypes = false // Must turn this off temporarily to enforce the file type
    allowedContentTypes = [type]

    DispatchQueue.main.async {
      self.allowsOtherFileTypes = otherFileTypesWereAllowed
    }
  }
}
