//
//  FinderTools.swift
//  FinderExtension
//
//  Created by cyan on 11/13/25.
//

import AppKit
import FinderSync
import os.log

final class FinderTools: FIFinderSync {
  override init() {
    super.init()

    FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
  }

  override var toolbarItemName: String {
    String(format: String(localized: "New %@ File"), fileBaseName)
  }

  override var toolbarItemToolTip: String {
    toolbarItemName
  }

  override var toolbarItemImage: NSImage {
    let symbols = [
      "text.pad.header.badge.plus",
      "document.badge.plus",
      "plus.square.on.square",
    ]

    for symbol in symbols {
      if let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil) {
        return image
      }
    }

    return super.toolbarItemImage
  }

  override func menu(for menuKind: FIMenuKind) -> NSMenu {
    let menu = NSMenu()
    let specs = fileTypes.map {
      String(format: String(localized: "New “%@%@”"), fileBaseName, $0)
    }

    for (index, title) in specs.enumerated() {
      let item = NSMenuItem(
        title: title,
        action: #selector(newTextFile(_:)),
        keyEquivalent: ""
      )

      item.tag = index
      menu.addItem(item)
    }

    if menuKind == .toolbarItemMenu {
      return menu
    }

    let itemWrapper = NSMenuItem(title: toolbarItemName, action: nil, keyEquivalent: "")
    itemWrapper.submenu = menu

    let menuWrapper = NSMenu()
    menuWrapper.addItem(itemWrapper)

    return menuWrapper
  }
}

// MARK: - Private

private let logger = os.Logger()
private let fileTypes = [".md", ".markdown", ".txt", ""]
private let fileBaseName = String(localized: "Untitled")

private extension FinderTools {
  @objc func newTextFile(_ sender: NSMenuItem) {
    guard let directory = FIFinderSyncController.default().targetedURL() else {
      return logger.log(level: .error, "Missing targetedURL")
    }

    let uniqueFileURL = FileManager.default.uniqueFileURL(
      in: directory,
      baseName: fileBaseName,
      pathExtension: fileTypes[sender.tag]
    )

    do {
      try Data().write(to: uniqueFileURL)
      NSWorkspace.shared.activateFileViewerSelecting([uniqueFileURL])
    } catch {
      logger.log(level: .error, "\(error)")
    }
  }
}

private extension FileManager {
  func uniqueFileURL(
    in directory: URL,
    baseName: String,
    pathExtension: String
  ) -> URL {
    var index = 1
    var fileName = "\(baseName)\(pathExtension)"

    while fileExists(atPath: directory.appending(path: fileName).path) {
      index += 1
      fileName = "\(baseName) \(index)\(pathExtension)"
    }

    return directory.appending(path: fileName)
  }
}
