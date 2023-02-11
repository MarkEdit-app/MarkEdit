//
//  NSApplication+Extension.swift
//
//  Created by cyan on 12/13/22.
//

import AppKit

public extension NSApplication {
  var isDarkMode: Bool {
    effectiveAppearance.isDarkMode
  }

  var shiftKeyIsPressed: Bool {
    currentEvent?.modifierFlags.contains(.shift) == true
  }

  func showOpenPanel() {
    if let openPanel = windows.first(where: { $0 is NSOpenPanel }) {
      openPanel.makeKeyAndOrderFront(self)
    } else {
      NSDocumentController.shared.openDocument(self)
    }
  }

  func closeOpenPanels() {
    for openPanel in windows where openPanel is NSOpenPanel {
      openPanel.close()
    }
  }
}
