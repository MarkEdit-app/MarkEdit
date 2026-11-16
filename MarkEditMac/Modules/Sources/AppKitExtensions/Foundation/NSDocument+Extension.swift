//
//  NSDocument+Extension.swift
//
//  Created by cyan on 1/21/23.
//

import AppKit

public extension NSDocument {
  var folderURL: URL? {
    fileURL?.deletingLastPathComponent()
  }

  var hasDifferentAutosavedFile: Bool {
    guard let autosavedContentsFileURL else {
      return false
    }

    return autosavedContentsFileURL != fileURL
  }

  /// Returns the file's bytes if they match the document's current serialized content; otherwise nil.
  var matchingFileData: Data? {
    get throws {
      guard let fileURL, let fileType else {
        return nil
      }

      let diskData = try Data(contentsOf: fileURL)
      return diskData == (try data(ofType: fileType)) ? diskData : nil
    }
  }

  /// Read the current disk version without asking other presenters to save their edits.
  func withCoordinatedFileRead(at url: URL, _ accessor: (URL, Date) throws -> Void) throws {
    var coordinationError: NSError?
    var fileReadError: Error?

    NSFileCoordinator(filePresenter: self).coordinate(
      readingItemAt: url,
      options: .withoutChanges,
      error: &coordinationError
    ) { coordinatedURL in
      do {
        let attributes = try FileManager.default.attributesOfItem(atPath: coordinatedURL.path)
        guard let date = attributes[.modificationDate] as? Date else {
          throw CocoaError(.fileReadUnknown)
        }

        try accessor(coordinatedURL, date)
      } catch {
        fileReadError = error
      }
    }

    if let error = coordinationError ?? fileReadError {
      throw error
    }
  }

  /// Unlike a main-queue dispatch, this can interrupt AppKit's synchronous document-access waits.
  nonisolated func continueOnMainActor(_ body: @Sendable @MainActor @escaping () -> Void) {
    continueAsynchronousWorkOnMainThread {
      // AppKit guarantees main-thread execution but does not annotate the callback's actor
      MainActor.assumeIsolated(body)
    }
  }

  func markContentDirty(_ isDirty: Bool) {
    // The undo stack is implemented in CoreEditor entirely,
    // there are only two meaningful change count values: 0 (saved) or 1 (dirty).
    updateChangeCount(isDirty ? .changeDone : .changeCleared)
  }

  func otherVersions(olderThanDays days: Int) -> [NSFileVersion] {
    guard let url = fileURL else {
      return []
    }

    guard let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: .now) else {
      return []
    }

    let all = NSFileVersion.otherVersionsOfItem(at: url) ?? []
    return days == 0 ? all : all.filter {
      ($0.modificationDate ?? .distantFuture) < cutoffDate
    }
  }

  func otherVersions(olderThanMaxLength maxLength: Int) -> [NSFileVersion] {
    guard let url = fileURL else {
      return []
    }

    let all = NSFileVersion.otherVersionsOfItem(at: url) ?? []
    let sorted = all.sorted {
      ($0.modificationDate ?? .distantPast) > ($1.modificationDate ?? .distantPast)
    }

    return maxLength > (sorted.count - 1) ? [] : Array(sorted.suffix(from: maxLength))
  }
}

public extension NSDocument.SaveOperationType {
  var updatesDocumentFile: Bool {
    self != .saveToOperation && self != .autosaveElsewhereOperation
  }

  var isInPlace: Bool {
    self == .saveOperation || self == .autosaveInPlaceOperation
  }
}
