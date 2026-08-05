//
//  RunLoop+Extension.swift
//
//  Created by cyan on 8/5/26.
//

import Foundation

public extension RunLoop {
  /// Performs a main-actor closure on the main run loop.
  static func performOnMain(
    modes: [RunLoop.Mode] = [.common],
    task: @Sendable @MainActor @escaping () -> Void
  ) {
    main.perform(inModes: modes) {
      MainActor.assumeIsolated(task)
    }
  }
}
