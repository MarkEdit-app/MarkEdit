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

  var optionKeyIsPressed: Bool {
    currentEvent?.modifierFlags.contains(.option) == true
  }

  @MainActor
  func showOpenPanel() {
    if let openPanel = (windows.first { $0 is NSOpenPanel }) {
      openPanel.makeKeyAndOrderFront(self)
    } else {
      NSDocumentController.shared.openDocument(self)
    }

    // [AppKit bug] NSOpenPanel is not reloaded automatically, resulting files cannot be opened.
    //
    // It can be reproduced after saving an iCloud file and quickly showing the openPanel,
    // even the built-in TextEdit.app has this problem.
    let validateOpenPanels = {
      self.openPanels.forEach {
        $0.validateVisibleColumns()
      }
    }

    // Ideally, we should observe changes using a File Coordinators or Kernel Queues,
    // but it is overly complicated.
    //
    // Validating twice with delays should be able to cover 90% of the cases.
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { validateOpenPanels() }
    DispatchQueue.main.asyncAfter(deadline: .now() + 4) { validateOpenPanels() }
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
