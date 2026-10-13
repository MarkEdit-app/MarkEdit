//
//  QuickSearchFilterLabels.swift
//
//  Created by cyan on 10/11/26.
//

import QuickSearchCore

public struct QuickSearchFilterLabels: Sendable {
  let title: String
  let currentDocument: String
  let options: [(filter: QuickSearchFilter, title: String)]

  public init(
    title: String,
    all: String,
    recents: String,
    bookmarks: String,
    headings: String,
    contents: String,
    menuActions: String,
    currentDocument: String
  ) {
    self.title = title
    self.currentDocument = currentDocument
    options = [
      (.all, all),
      (.recents, recents),
      (.bookmarks, bookmarks),
      (.menuActions, menuActions),
      (.headings, headings),
      (.contents, contents),
    ]
  }
}
