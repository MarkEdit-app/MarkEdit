//
//  NSWorkspace+Extension.swift
//
//  Created by cyan on 7/12/26.
//

#if os(macOS)

import AppKit

public extension NSWorkspace {
  /// Launches a fresh instance of the current app, then terminates this one.
  func relaunchApp() {
    let configuration = OpenConfiguration()
    configuration.createsNewApplicationInstance = true

    openApplication(at: Bundle.main.bundleURL, configuration: configuration) { _, _ in
      Task { @MainActor in
        NSApp.terminate(nil)
      }
    }
  }
}

#endif
