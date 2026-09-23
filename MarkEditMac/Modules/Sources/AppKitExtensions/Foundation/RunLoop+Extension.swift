//
//  RunLoop+Extension.swift
//
//  Created by cyan on 8/5/26.
//

import Foundation

public extension RunLoop {
  /// Defers work to the main run loop in the requested modes, including event tracking by default.
  /// Unlike a task hop, this preserves run-loop mode scheduling and never blocks the caller.
  static func performOnMain(
    modes: [RunLoop.Mode] = [.common],
    task: @Sendable @MainActor @escaping () -> Void
  ) {
    main.perform(inModes: modes) {
      // Foundation runs this callback on the main run loop but does not express actor isolation.
      MainActor.assumeIsolated(task)
    }
  }
}
