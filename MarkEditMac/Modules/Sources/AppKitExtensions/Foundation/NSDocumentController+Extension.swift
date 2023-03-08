//
//  NSDocumentController+Extension.swift
//
//  Created by cyan on 3/8/23.
//

import AppKit

public extension NSDocumentController {
  /**
   Just to help us call NSDocumentController.shared earlier, nothing else to do.

   Based on observations, there're rare cases where recents are not opened correctly,
   it **seems** less severe with this trick.
   */
  func warmUp() {
    // no-op
  }
}
