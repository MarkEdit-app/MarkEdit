//
//  UpdateRunner.swift
//  UpdateInstaller
//
//  Created by cyan on 8/2/26.
//

import Foundation
import OSLog
import UpdaterCore

/**
 Detached installer that swaps the verified app after MarkEdit exits.
 */
enum UpdateRunner {
  private static let exitTimeout: TimeInterval = 60

  static func run() {
    guard let arguments = InstallerArguments(parsing: CommandLine.arguments) else {
      return updaterLog.error("Installer started without the required arguments")
    }

    guard let target = hostBundlePath else {
      return updaterLog.error("Installer is not embedded in an application bundle")
    }

    defer {
      if arguments.relaunch {
        relaunch(target: target)
      }
    }

    // Restrict cleanup to recognized staging directory names
    guard let staging = StagingLocation.directory(of: arguments.stagedPath) else {
      return updaterLog.error("Installer started with an unexpected staged path")
    }

    defer {
      try? FileManager.default.removeItem(at: staging)
    }

    guard waitForExit(processIdentifier: arguments.processIdentifier) else {
      return updaterLog.error("MarkEdit is still running, aborting the update")
    }

    do {
      try install(staged: arguments.stagedPath, target: target)
    } catch {
      return updaterLog.error("Failed to install the update: \(error.localizedDescription, privacy: .public)")
    }
  }
}

// MARK: - Private

private extension UpdateRunner {
  enum Failure: LocalizedError {
    case swapFailed(Int32)

    var errorDescription: String? {
      switch self {
      case .swapFailed(let code):
        return "The application could not be replaced (errno \(code))"
      }
    }
  }

  static func install(staged: String, target: String) throws {
    // Reverify after waiting for the app to exit
    let requirement = try BundleVerifier.designatedRequirement(of: target)
    try BundleVerifier.check(path: staged, against: requirement)
    try BundleVerifier.checkIdentity(of: staged, matching: target)

    guard swap(staged: staged, target: target) else {
      throw Failure.swapFailed(errno)
    }

    touch(path: target)
    updaterLog.info("Installed the update at \(target, privacy: .public)")
  }

  /// Refreshes LaunchServices after replacement.
  static func touch(path: String) {
    let descriptor = open(path, O_RDONLY | O_SYMLINK)
    guard descriptor != -1 else {
      return
    }

    defer { close(descriptor) }
    _ = futimes(descriptor, nil)
  }

  static func swap(staged: String, target: String) -> Bool {
    staged.withCString { staged in
      target.withCString { target in
        renamex_np(staged, target, UInt32(RENAME_SWAP)) == 0
      }
    }
  }

  /// Waits for the app to quit, the swap only needs its process gone.
  static func waitForExit(processIdentifier pid: Int32) -> Bool {
    let deadline = Date(timeIntervalSinceNow: exitTimeout)

    while Date() < deadline {
      if kill(pid, 0) != 0 && errno == ESRCH {
        return true
      }

      usleep(100 * 1000)
    }

    return false
  }

  static func relaunch(target: String) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    process.arguments = [target]

    do {
      try process.run()
    } catch {
      updaterLog.error("Failed to relaunch: \(error.localizedDescription, privacy: .public)")
    }
  }
}
