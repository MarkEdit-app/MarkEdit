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

    // [AppKit bug] NSOpenPanel is not reloaded automatically, resulting files cannot be opened.
    //
    // It can be reproduced after saving an iCloud file and quickly showing the openPanel,
    // even the built-in TextEdit.app has this problem.
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
      self.openPanels.forEach {
        $0.validateVisibleColumns()
      }
    }
  }

  func closeOpenPanels() {
    openPanels.forEach { $0.close() }
  }
}

// MARK: - Private

private extension NSApplication {
  var openPanels: [NSOpenPanel] {
    windows.compactMap { $0 as? NSOpenPanel }
  }
}
