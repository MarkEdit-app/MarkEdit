//
//  Thread+Extension.swift
//
//  Created by cyan on 6/11/26.
//

import Foundation

public extension Thread {
  /// Run a main-actor closure, synchronously when already on the main thread, otherwise hopped to the main queue.
  ///
  /// Prefer this over `Task { @MainActor in }` for UI updates that must land in the current
  /// runloop turn (e.g. KVO/observation callbacks), to avoid a one-frame stale paint.
  static func ensureMain(_ body: @Sendable @MainActor @escaping () -> Void) {
    if Self.isMainThread {
      MainActor.assumeIsolated(body)
    } else {
      DispatchQueue.main.async {
        MainActor.assumeIsolated(body)
      }
    }
  }
}
