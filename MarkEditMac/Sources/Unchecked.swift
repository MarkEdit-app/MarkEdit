//
//  Unchecked.swift
//  MarkEditMac
//
//  Created by cyan on 2024/4/17.
//

import WebKit
import AppIntents

extension WKProcessPool: @unchecked Sendable {}
extension IntentDescription: @unchecked Sendable {}
extension TypeDisplayRepresentation: @unchecked Sendable {}

extension MainActor {
  @_unavailableFromAsync
  static func unsafeIgnoreIsolation<T>(_ operation: @MainActor () throws -> T) rethrows -> T {
    try withoutActuallyEscaping(operation) { fn in
      let rawFn = unsafeBitCast(fn, to: (() throws -> T).self)
      return try rawFn()
    }
  }
}
