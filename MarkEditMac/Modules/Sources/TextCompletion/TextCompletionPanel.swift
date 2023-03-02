//
//  TextCompletionPanel.swift
//
//  Created by cyan on 3/2/23.
//

import AppKit

final class TextCompletionPanel: NSPanel {
  init() {
    super.init(
      contentRect: .zero,
      styleMask: .borderless,
      backing: .buffered,
      defer: false
    )
  }
}
