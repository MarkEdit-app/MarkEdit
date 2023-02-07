//
//  EditorViewController+HyperLink.swift
//  MarkEditMac
//
//  Created by cyan on 1/4/23.
//

import AppKit
import MarkEditKit

extension EditorViewController {
  func insertHyperLink(prefix: String?) {
    Task {
      guard let text = try? await bridge.selection.getText() else {
        return
      }

      let prefersURL = text == NSDataDetector.extractURL(from: text)
      let defaultTitle = Localized.Editor.defaultLinkTitle
      let title = (text.isEmpty || text.components(separatedBy: .newlines).count > 1) ? defaultTitle : text

      // Try our best to guess from selection and clipboard
      bridge.format.insertHyperLink(
        title: prefersURL ? defaultTitle : title,
        url: prefersURL ? text : (NSPasteboard.general.url ?? "https://"),
        prefix: prefix
      )
    }
  }
}
