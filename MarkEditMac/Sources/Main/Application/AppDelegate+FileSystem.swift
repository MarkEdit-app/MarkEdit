//
//  AppDelegate+FileSystem.swift
//  MarkEditMac
//
//  Created by cyan on 4/30/24.
//

import AppKit
import MarkEditKit

extension AppDelegate {
  func saveGrantedFolderAsBookmark() async {
    let openPanel = NSOpenPanel()
    openPanel.prompt = Localized.General.grantAccess
    openPanel.canChooseDirectories = true
    openPanel.canChooseFiles = false
    openPanel.allowsMultipleSelection = false

    guard await openPanel.begin() == .OK, let url = openPanel.url else {
      return
    }

    guard let newBookmark = try? url.bookmarkData(
      options: .withSecurityScope,
      includingResourceValuesForKeys: nil,
      relativeTo: nil
    ) else {
      return Logger.log(.error, "Failed to create bookmark data")
    }

    let bookmarkData = AppPreferences.General.grantedFolderBookmark
    let bookmarkList: [Data] = {
      if let dataArray = bookmarkData?.decodeToDataArray() {
        return dataArray
      }

      if let bookmarkData {
        return [bookmarkData]
      }

      return []
    }()

    let encodedData = bookmarkList.appendingData(newBookmark).encodeToData()
    AppPreferences.General.grantedFolderBookmark = encodedData
  }

  func startAccessingGrantedFolder() {
    guard let bookmarkData = AppPreferences.General.grantedFolderBookmark else {
      return
    }

    if let bookmarkList = bookmarkData.decodeToDataArray() {
      bookmarkList.forEach {
        startAccessingBookmarkData($0)
      }
    } else {
      startAccessingBookmarkData(bookmarkData)
    }
  }
}

// MARK: - Private

private extension AppDelegate {
  func startAccessingBookmarkData(_ bookmarkData: Data) {
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
