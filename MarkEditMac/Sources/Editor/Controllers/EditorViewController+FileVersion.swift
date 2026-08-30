//
//  EditorViewController+FileVersion.swift
//  MarkEdit
//
//  Created by cyan on 11/10/24.
//

import AppKit
import MarkEditKit

extension EditorViewController {
  func deleteFileVersions(_ versions: [NSFileVersion]) async {
    let alert = NSAlert()
    alert.alertStyle = .warning

    guard !versions.isEmpty else {
      alert.messageText = Localized.FileVersion.noVersionsTitle
      await presentSheetModal(alert)
      return
    }

    guard let fileURL = document?.fileURL else {
      return Logger.assertFail("Missing file URL when deleting versions")
    }

    alert.messageText = String(format: Localized.FileVersion.foundVersionsFormat, versions.count)
    alert.informativeText = Localized.FileVersion.cannotBeUndone

    alert.addButton(withTitle: Localized.General.delete)
    alert.addButton(withTitle: Localized.General.cancel)

    guard await presentSheetModal(alert) == .alertFirstButtonReturn else {
      return
    }

    do {
      for version in versions {
        try await version.removeFromDisk(for: fileURL)
      }
    } catch {
      Logger.log(.error, error.localizedDescription)
    }
  }
}
