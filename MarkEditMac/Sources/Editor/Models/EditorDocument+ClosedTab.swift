//
//  EditorDocument+ClosedTab.swift
//  MarkEditMac
//
//  Created by cyan on 4/16/26.
//

import AppKit

// MARK: - Closed Tab

extension EditorDocument {
  func saveToClosedTabHistory() {
    guard let fileURL else {
      return
    }

    // Fallback: capture tab info if windowShouldClose didn't run (programmatic close)
    if lastTabIndex == nil, let window = windowControllers.first?.window {
      let tabbedWindows = window.tabbedWindows
      lastTabIndex = tabbedWindows?.firstIndex(of: window)
      lastWasStandalone = tabbedWindows == nil || tabbedWindows?.count == 1
      lastSiblingWindow = tabbedWindows?.first { $0 !== window }
    }

    EditorClosedTabHistory.shared.push(
      fileURL,
      tabIndex: lastTabIndex,
      sourceWindow: lastSiblingWindow,
      wasStandalone: lastWasStandalone
    )
  }

  func restoreTabPosition(tabIndex: Int?, relativeTo targetWindow: NSWindow?) {
    guard let newWindow = windowControllers.first?.window else {
      return
    }

    guard let tabIndex,
          let targetWindow,
          let tabGroup = targetWindow.tabGroup else {
      return
    }

    let tabbedWindows = targetWindow.tabbedWindows ?? []

    guard tabbedWindows.count > 1,
          let currentIndex = tabbedWindows.firstIndex(of: newWindow),
          currentIndex != tabIndex else {
      return
    }

    // Off-by-one: compute after removal since tab count shrinks
    tabGroup.removeWindow(newWindow)
    let clampedIndex = min(tabIndex, tabGroup.windows.count)
    tabGroup.insertWindow(newWindow, at: clampedIndex)

    newWindow.makeKeyAndOrderFront(nil)
    tabGroup.selectedWindow = newWindow
  }
}
