//
//  NSDocumentController+Extension.swift
//
//  Created by cyan on 7/12/26.
//

import AppKit

public extension NSDocumentController {
  /**
   Force the override of the last root directory for NSOpenPanel and NSSavePanel.
   */
  func setOpenPanelDirectory(_ directory: String) {
    UserDefaults.standard.set(directory, forKey: "NSNavLastRootDirectory")
  }
}
