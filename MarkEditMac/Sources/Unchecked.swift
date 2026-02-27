//
//  Unchecked.swift
//  MarkEditMac
//
//  Created by cyan on 4/17/24.
//

import WebKit
import AppIntents
import MarkEditCore

extension MainActor {
  @_unavailableFromAsync
  static func unsafeIgnoreIsolation<T>(_ operation: @MainActor () throws -> T) rethrows -> T {
    try withoutActuallyEscaping(operation) { fn in
      let rawFn = unsafeBitCast(fn, to: (() throws -> T).self)
      return try rawFn()
    }
  }
}
