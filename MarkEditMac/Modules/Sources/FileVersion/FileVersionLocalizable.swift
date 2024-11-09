//
//  FileVersionLocalizable.swift
//
//  Created by cyan on 2024/10/17.
//

import Foundation

public struct FileVersionLocalizable: Sendable {
  let previous: String
  let next: String
  let cancel: String
  let revertTitle: String
  let modeTitles: [String]

  public init(
    previous: String,
    next: String,
    cancel: String,
    revertTitle: String,
    modeTitles: [String]
  ) {
    self.previous = previous
    self.next = next
    self.cancel = cancel
    self.revertTitle = revertTitle
    self.modeTitles = modeTitles
  }
}
