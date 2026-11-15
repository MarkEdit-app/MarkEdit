//
//  EditorDocument+FileVersion.swift
//  MarkEditMac
//
//  Created by cyan on 12/12/22.

import AppKit
import AppKitExtensions
import MarkEditKit
import FileVersion

extension EditorDocument: FileVersionPickerDelegate {
  func presentFileVersions(_ sender: Any?) {
    guard let fileURL else {
      return Logger.assertFail("Missing fileURL for document: \(self)")
    }

    let localVersions = {
      let otherVersions = NSFileVersion.otherVersionsOfItem(at: fileURL) ?? []
      Logger.log(.debug, "Found \(otherVersions.count) local versions")

      if otherVersions.isEmpty, let currentVersion = NSFileVersion.currentVersionOfItem(at: fileURL) {
        return [currentVersion]
      }

      let sortedVersions = otherVersions.newestToOldest()
      let differentIndex = sortedVersions.firstIndex {
        // Find the first version that differs from the current one
        (try? Data(contentsOf: $0.url))?.toString() != stringValue
      }

      return Array(sortedVersions.suffix(from: differentIndex ?? 0))
    }()

    guard !localVersions.isEmpty else {
      return Logger.assertFail("File \(fileURL) has no local versions")
    }

    let picker = FileVersionPicker(
      fileURL: fileURL,
      currentText: stringValue,
      localVersions: localVersions,
      localizable: FileVersionLocalizable(
        previous: Localized.General.previous,
        next: Localized.General.next,
        cancel: Localized.General.cancel,
        revertTitle: Localized.FileVersion.revertTitle,
        modeTitles: Localized.FileVersion.modeTitles
      ),
      delegate: self
    )

    hostViewController?.presentAsSheet(picker)
  }

  func fileVersionPicker(_ picker: FileVersionPicker, didPickVersion version: NSFileVersion) async {
    guard let contents = try? Data(contentsOf: version.url).toString() else {
      return Logger.assertFail("Failed to get file contents of version: \(version)")
    }

    stringValue = contents
    hostViewController?.resetEditor(resetSelection: true)

    await hostViewController?.waitUntilEditorReset()
    await waitUntilSaveCompleted()
  }

  func fileVersionPicker(_ picker: FileVersionPicker, didBecomeSheet: Bool) {
    hostViewController?.setHasModalSheet(value: didBecomeSheet)
  }
}
