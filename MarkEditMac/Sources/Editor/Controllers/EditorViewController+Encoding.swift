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
      return Logger.assertFail("Invalid encoding: \(String(describing: sender.representedObject))")
    }

    guard let data = document?.fileData else {
      return Logger.assertFail("Missing fileData from: \(String(describing: document))")
    }

    document?.stringValue = encoding.decode(data: data)
    resetEditor()
  }
}
