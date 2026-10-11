//
//  AppDelegate+FileSystem.swift
//  MarkEditMac
//
//  Created by cyan on 4/30/24.
//

import AppKit
import AppKitExtensions
import MarkEditKit

extension AppDelegate {
  func addBookmarks() async {
    let openPanel = NSOpenPanel()
    openPanel.prompt = Localized.Bookmarks.addBookmarksPrompt
    openPanel.message = Localized.Bookmarks.accessMessage
    openPanel.canChooseDirectories = true
    openPanel.canChooseFiles = true
    openPanel.allowsMultipleSelection = true

    guard await openPanel.begin() == .OK else {
      return
    }

    performBookmarkChange {
      try bookmarkStore.add(openPanel.urls)
    }
  }

  func startAccessingBookmarks() {
    _ = bookmarkStore.load()
  }

  func performBookmarkChange(_ change: () throws -> Void) {
    do {
      try change()
    } catch {
      Logger.log(.error, "Bookmark: \(error.localizedDescription)")
      NSApp.presentError(error)
    }
  }
}
