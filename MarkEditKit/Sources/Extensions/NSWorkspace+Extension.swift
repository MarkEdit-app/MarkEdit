//
//  NSWorkspace+Extension.swift
//
//  Created by cyan on 7/12/26.
//

#if os(macOS)

import AppKit

public extension NSWorkspace {
  /// Terminates this instance, then launches a fresh one.
  func relaunchApp() {
    let path = Bundle.main.bundleURL
    let pid = ProcessInfo.processInfo.processIdentifier
    let task = Process()

    // A detached helper waits for this process to exit before reopening, so the new
    // instance never coexists with the old one and no second Dock icon appears.
    task.executableURL = URL(filePath: "/bin/sh")
    task.arguments = [
      "-c",
      [
        "while /bin/kill -0 \(pid) >/dev/null 2>&1",
        "do /bin/sleep 0.1; done",
        "/usr/bin/open \"$1\"",
      ].joined(separator: "; "),
      "sh", // $0
      path.path(percentEncoded: false), // $1
    ]

    do {
      try task.run()
      Task { @MainActor in
        NSApp.terminate(nil)
      }
    } catch {
      // Fallback to opening a new app instance
      Logger.log(.error, "Failed to spawn the relaunch helper: \(error)")
      openNewAppInstance(at: path)
    }
  }
}

// MARK: - Private

private extension NSWorkspace {
  func openNewAppInstance(at url: URL) {
    let configuration = OpenConfiguration()
    configuration.createsNewApplicationInstance = true

    openApplication(at: url, configuration: configuration) { _, _ in
      Task { @MainActor in
        NSApp.terminate(nil)
      }
    }
  }
}

#endif
