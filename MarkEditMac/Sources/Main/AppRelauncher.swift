//
//  AppRelauncher.swift
//  MarkEditMac
//
//  Created by cyan on 8/5/26.
//

import AppKit
import MarkEditKit

@MainActor
enum AppRelauncher {
  private(set) static var isRequested = false
  private(set) static var isSafeMode = false

  static func request(safeMode: Bool = false) {
    isRequested = true
    isSafeMode = safeMode
  }

  static func cancel() {
    isRequested = false
    isSafeMode = false
  }

  static func commit() {
    guard isRequested else {
      return
    }

    if isSafeMode {
      AppCustomization.requestSafeMode()
    } else {
      AppCustomization.cancelSafeMode()
    }
  }

  static func scheduleIfRequested() {
    guard isRequested else {
      return
    }

    isRequested = false
    isSafeMode = false

    let path = Bundle.main.bundleURL
    let pid = ProcessInfo.processInfo.processIdentifier
    let task = Process()

    // Wait for this process to exit before opening the next instance.
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
    } catch {
      Logger.log(.error, "Failed to spawn the relaunch helper: \(error)")
      openNewAppInstance(at: path)
    }
  }
}

// MARK: - Private

private extension AppRelauncher {
  static func openNewAppInstance(at url: URL) {
    let configuration = NSWorkspace.OpenConfiguration()
    configuration.createsNewApplicationInstance = true

    let workspace = NSWorkspace.shared
    workspace.openApplication(
      at: url,
      configuration: configuration
    ) { _, _ in }
  }
}
