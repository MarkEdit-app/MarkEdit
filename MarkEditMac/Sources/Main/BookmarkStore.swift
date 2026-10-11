//
//  BookmarkStore.swift
//
//  Created by cyan on 10/11/26.
//

import Foundation
import AppKitExtensions
import MarkEditKit

@MainActor
final class BookmarkStore {
  static let shared = BookmarkStore(
    read: { AppPreferences.General.fileBookmarks },
    write: { AppPreferences.General.fileBookmarks = $0 },
    reportError: { Logger.log(.error, "Bookmark: \($0.localizedDescription)") }
  )

  struct Bookmark {
    let data: Data
    let url: URL?
    let error: Error?
  }

  private let read: () -> Data?
  private let write: (Data?) -> Void
  private let reportError: (Error) -> Void
  private var accessedBookmarks: [Data: URL] = [:]

  init(
    read: @escaping () -> Data?,
    write: @escaping (Data?) -> Void,
    reportError: @escaping (Error) -> Void
  ) {
    self.read = read
    self.write = write
    self.reportError = reportError
  }

  deinit {
    accessedBookmarks.values.forEach {
      $0.stopAccessingSecurityScopedResource()
    }
  }

  func load() -> [Bookmark] {
    let bookmarks: [Data]
    if let data = read() {
      bookmarks = data.decodeToDataArray() ?? [data]
    } else {
      bookmarks = []
    }

    stopAccessing(except: Set(bookmarks))
    return bookmarks.map { data in
      do {
        var isStale = false
        let url = try URL(
          resolvingBookmarkData: data,
          options: [.withSecurityScope, .withoutUI, .withoutMounting],
          relativeTo: nil,
          bookmarkDataIsStale: &isStale
        )

        if let accessed = accessedBookmarks[data], accessed.standardizedFileURL != url.standardizedFileURL {
          accessed.stopAccessingSecurityScopedResource()
          accessedBookmarks.removeValue(forKey: data)
        }

        if accessedBookmarks[data] == nil {
          guard url.startAccessingSecurityScopedResource() else {
            throw CocoaError(.fileReadNoPermission, userInfo: [NSURLErrorKey: url])
          }

          accessedBookmarks[data] = url
        }

        return Bookmark(data: data, url: url, error: nil)
      } catch {
        reportError(error)
        return Bookmark(data: data, url: nil, error: error)
      }
    }
  }

  func add(_ urls: [URL]) throws {
    var bookmarks = load()
    for url in urls {
      let data = try url.bookmarkData(
        options: .withSecurityScope,
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )

      let bookmark = Bookmark(data: data, url: url, error: nil)
      if let index = (bookmarks.firstIndex { $0.url?.standardizedFileURL == url.standardizedFileURL }) {
        bookmarks[index] = bookmark
      } else {
        bookmarks.append(bookmark)
      }
    }

    try persist(bookmarks.map(\.data))
    _ = load()
  }

  func revoke(_ bookmark: Bookmark) throws {
    let remaining = load().filter {
      if $0.data == bookmark.data {
        return false
      }

      guard let url = bookmark.url else {
        return true
      }

      return $0.url?.standardizedFileURL != url.standardizedFileURL
    }

    try persist(remaining.map(\.data))
  }

  func revokeAll() {
    write(nil)
    stopAccessing(except: [])
  }

  private func persist(_ bookmarks: [Data]) throws {
    let data = bookmarks.isEmpty ? nil : try PropertyListEncoder().encode(bookmarks)
    write(data)
    stopAccessing(except: Set(bookmarks))
  }

  private func stopAccessing(except bookmarks: Set<Data>) {
    for data in Array(accessedBookmarks.keys) where !bookmarks.contains(data) {
      accessedBookmarks.removeValue(forKey: data)?.stopAccessingSecurityScopedResource()
    }
  }
}
