//
//  AppDelegate+FileSystem.swift
//  MarkEditMac
//
//  Created by cyan on 2024/4/30.
//

import AppKit
import MarkEditKit

extension AppDelegate {
  func saveGrantedFolderAsBookmark() {
    let openPanel = NSOpenPanel()
    openPanel.prompt = Localized.General.grantAccess
    openPanel.canChooseDirectories = true
    openPanel.canChooseFiles = false
    openPanel.allowsMultipleSelection = false

    guard openPanel.runModal() == .OK, let url = openPanel.url else {
      return
    }

    do {
      AppPreferences.General.grantedFolderBookmark = try url.bookmarkData(
        options: .withSecurityScope,
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )
    } catch {
      Logger.log(.error, "Failed to create bookmark data")
    }
  }

  func startAccessingGrantedFolder() {
    guard let bookmarkData = AppPreferences.General.grantedFolderBookmark else {
      return
    }

    do {
      var isStale = false
      let bookmarkURL = try URL(
        resolvingBookmarkData: bookmarkData,
        options: .withSecurityScope,
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      )

      if !bookmarkURL.startAccessingSecurityScopedResource() {
        Logger.log(.error, "Failed to start accessing security scoped resource")
      }
    } catch {
      Logger.log(.error, "Failed to resolve bookmark data")
    }
  }
}
