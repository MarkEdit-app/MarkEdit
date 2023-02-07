//
//  EditorViewController+Encoding.swift
//  MarkEditMac
//
//  Created by cyan on 1/3/23.
//

import AppKit
import MarkEditKit

extension EditorViewController {
  @objc func reopenWithEncoding(_ sender: NSMenuItem) {
    guard let encoding = sender.representedObject as? EditorTextEncoding else {
      return
    }

    guard let data = document?.fileData, let string = encoding.decode(data: data) else {
      return
    }

    document?.stringValue = string
    resetEditor()
  }
}
