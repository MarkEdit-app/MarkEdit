//
//  EditorViewController+LineEndings.swift
//  MarkEditMac
//
//  Created by cyan on 1/28/23.
//

import AppKit
import MarkEditKit

extension EditorViewController {
  @IBAction func setLineEndings(_ sender: Any?) {
    guard let item = sender as? NSMenuItem else {
      return Logger.assertFail("Invalid sender")
    }

    guard let lineEndings = LineEndings(rawValue: item.tag) else {
      return Logger.assertFail("Invalid lineEndings: \(item.tag)")
    }

    document?.save(sender)
    bridge.lineEndings.setLineEndings(lineEndings: lineEndings)
  }
}
