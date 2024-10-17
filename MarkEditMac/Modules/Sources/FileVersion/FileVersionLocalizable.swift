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
  let pickThisVersion: String
  let modeTitles: [String]

  public init(
    previous: String,
    next: String,
    cancel: String,
    pickThisVersion: String,
    modeTitles: [String]
  ) {
    self.previous = previous
    self.next = next
    self.cancel = cancel
    self.pickThisVersion = pickThisVersion
    self.modeTitles = modeTitles
  }
}
