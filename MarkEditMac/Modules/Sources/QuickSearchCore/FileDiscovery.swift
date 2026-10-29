//
//  FileDiscovery.swift
//
//  Created by cyan on 10/11/26.
//

import Foundation

package enum FileDiscovery {
  package struct Batch: Sendable {
    package var urls: [URL]
    package var errors: [String]

    package init(urls: [URL] = [], errors: [String] = []) {
      self.urls = urls
      self.errors = errors
    }
  }

  package static func scan(
    _ locations: QuickSearchLocations,
    onBatch: @Sendable (Batch) async -> Void
  ) async throws {
    let keys: Set<URLResourceKey> = [
      .isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey, .isHiddenKey, .isPackageKey, .contentTypeKey,
    ]

    let options: FileManager.DirectoryEnumerationOptions = locations.showsHiddenFiles
      ? [.skipsPackageDescendants] : [.skipsPackageDescendants, .skipsHiddenFiles]

    var seen = Set<URL>()
    var batch = Batch()
    var lastUpdate = ContinuousClock.now

    func flushIfNeeded() async {
      guard batch.urls.count >= 100 || lastUpdate.duration(to: .now) >= .milliseconds(100) else {
        return
      }

      await onBatch(batch)
      batch = Batch()
      lastUpdate = .now
    }

    func include(_ url: URL, values: URLResourceValues) -> Bool {
      if values.isDirectory == true {
        return url.pathExtension.lowercased() == "textbundle"
      }

      return values.isRegularFile == true && locations.isFileEligible(url)
    }

    for root in locations.urls {
      try Task.checkCancellation()

      let root = root.standardizedFileURL
      guard seen.insert(root).inserted else {
        continue
      }

      do {
        let values = try root.resourceValues(forKeys: keys)
        guard values.isSymbolicLink != true, locations.showsHiddenFiles || values.isHidden != true else {
          continue
        }

        if include(root, values: values) {
          batch.urls.append(root)
          await flushIfNeeded()
        }

        guard values.isDirectory == true,
              values.isPackage != true,
              root.pathExtension.lowercased() != "textbundle" else {
          continue
        }

        guard let enumerator = FileManager.default.enumerator(
          at: root,
          includingPropertiesForKeys: Array(keys),
          options: options,
          errorHandler: { url, error in
            batch.errors.append("\(url.path): \(error.localizedDescription)")
            return true
          }
        ) else {
          throw CocoaError(.fileReadUnknown, userInfo: [NSFilePathErrorKey: root.path])
        }

        while let url = enumerator.nextObject() as? URL {
          try Task.checkCancellation()

          let url = url.standardizedFileURL
          guard seen.insert(url).inserted else {
            enumerator.skipDescendants()
            continue
          }

          do {
            let values = try url.resourceValues(forKeys: keys)
            if values.isSymbolicLink == true {
              enumerator.skipDescendants()
              continue
            }

            if include(url, values: values) {
              batch.urls.append(url)
            }

            if values.isDirectory == true && (values.isPackage == true || url.pathExtension.lowercased() == "textbundle") {
              enumerator.skipDescendants()
            }
          } catch {
            batch.errors.append("\(url.path): \(error.localizedDescription)")
          }

          await flushIfNeeded()
        }
      } catch is CancellationError {
        throw CancellationError()
      } catch {
        batch.errors.append("\(root.path): \(error.localizedDescription)")
      }
    }

    try Task.checkCancellation()
    await onBatch(batch)
  }
}
