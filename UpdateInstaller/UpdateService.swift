//
//  UpdateService.swift
//  UpdateInstaller
//
//  Created by cyan on 8/2/26.
//

import Foundation
import OSLog
import UpdaterCore

let updaterLog = Logger(subsystem: "app.cyan.markedit", category: "updater")

/**
 XPC service that stages updates and starts the detached installer.
 */
final class UpdateService: NSObject, UpdateInstalling {
  func prepareUpdate(archivePath: String) async throws -> String {
    do {
      return try stage(archivePath: archivePath)
    } catch {
      updaterLog.error("Failed to stage the update: \(error.localizedDescription, privacy: .public)")
      throw error.transportable
    }
  }

  func commitUpdate(
    stagedPath: String,
    processIdentifier: Int32,
    relaunch: Bool,
    reply: @escaping (String?) -> Void
  ) {
    do {
      try spawnInstaller(
        stagedPath: stagedPath,
        processIdentifier: processIdentifier,
        relaunch: relaunch
      )

      reply(nil)
    } catch {
      updaterLog.error("Failed to spawn the installer: \(error.localizedDescription, privacy: .public)")
      reply(error.localizedDescription)
    }
  }

  func discardUpdate(stagedPath: String) async throws {
    guard let staging = StagingLocation.directory(of: stagedPath) else {
      updaterLog.error("Refused to discard an unexpected path")
      throw Failure.invalidStaging.transportable
    }

    try? FileManager.default.removeItem(at: staging)
  }
}

// MARK: - Private

private extension UpdateService {
  enum Failure: LocalizedError {
    case invalidStaging
    case unknownHost
    case readOnlyLocation
    case missingInstaller
    case extractionFailed(Int32)
    case missingBundle

    var errorDescription: String? {
      switch self {
      case .invalidStaging:
        return "The update is missing or was not staged by MarkEdit"
      case .unknownHost:
        return "The installer could not locate the application to update"
      case .readOnlyLocation:
        return "MarkEdit doesn't have permission to update itself at this location"
      case .missingInstaller:
        return "The installer is missing from the application bundle"
      case .extractionFailed(let code):
        return "The downloaded archive could not be extracted (ditto exited with \(code))"
      case .missingBundle:
        return "The downloaded archive does not contain an application"
      }
    }
  }

  func stage(archivePath: String) throws -> String {
    guard let targetPath = hostBundlePath else {
      throw Failure.unknownHost
    }

    // Verify the installed app before trusting its requirement
    let requirement = try BundleVerifier.designatedRequirement(of: targetPath)
    try BundleVerifier.check(path: targetPath, against: requirement)

    // E.g., "/Applications/MarkEdit.app" should be writable
    guard FileManager.default.isWritableFile(atPath: targetPath) else {
      throw Failure.readOnlyLocation
    }

    // E.g., "/Applications" should be also be writable
    let enclosing = URL(fileURLWithPath: targetPath).deletingLastPathComponent()
    guard FileManager.default.isWritableFile(atPath: enclosing.path(percentEncoded: false)) else {
      throw Failure.readOnlyLocation
    }

    // Keep staging on the target volume for an atomic swap
    let parent = try FileManager.default.url(
      for: .itemReplacementDirectory,
      in: .userDomainMask,
      appropriateFor: URL(fileURLWithPath: targetPath),
      create: true
    )

    let staging = parent.appending(
      path: StagingLocation.prefix + UUID().uuidString,
      directoryHint: .isDirectory
    )

    try FileManager.default.createDirectory(
      at: staging,
      withIntermediateDirectories: true
    )

    do {
      try extract(archivePath: archivePath, into: staging)
      clearQuarantine(at: staging)

      let contents = try FileManager.default.contentsOfDirectory(
        at: staging,
        includingPropertiesForKeys: [.isSymbolicLinkKey]
      )

      guard let bundle = (contents.first { $0.pathExtension == "app" }),
            try bundle.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink == false else {
        throw Failure.missingBundle
      }

      let stagedPath = bundle.path(percentEncoded: false)
      try BundleVerifier.checkIdentity(of: stagedPath, matching: targetPath)
      try BundleVerifier.check(path: stagedPath, against: requirement)

      updaterLog.info("Staged a verified update at \(stagedPath, privacy: .public)")
      return stagedPath
    } catch {
      try? FileManager.default.removeItem(at: staging)
      throw error
    }
  }

  func extract(archivePath: String, into directory: URL) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
    process.arguments = ["-x", "-k", archivePath, directory.path(percentEncoded: false)]

    try process.run()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
      throw Failure.extractionFailed(process.terminationStatus)
    }
  }

  /// Removes quarantine so Gatekeeper permits relaunch.
  func clearQuarantine(at directory: URL) {
    let enumerated = (FileManager.default.enumerator(
      at: directory,
      includingPropertiesForKeys: nil
    ))?.compactMap { $0 as? URL }

    for item in [directory] + (enumerated ?? []) {
      item.withUnsafeFileSystemRepresentation { path in
        guard let path else {
          return
        }

        _ = removexattr(path, "com.apple.quarantine", XATTR_NOFOLLOW)
      }
    }
  }

  /// Starts the installer detached, so it survives both this service and the app.
  func spawnInstaller(stagedPath: String, processIdentifier: Int32, relaunch: Bool) throws {
    guard StagingLocation.directory(of: stagedPath) != nil else {
      throw Failure.invalidStaging
    }

    guard let installer = installerPath else {
      throw Failure.missingInstaller
    }

    let arguments = InstallerArguments(
      stagedPath: stagedPath,
      processIdentifier: processIdentifier,
      relaunch: relaunch
    )

    try spawnDetached(executable: installer, arguments: arguments.commandLine)
  }

  /// Executable reused by the detached installer.
  var installerPath: String? {
    guard let path = Bundle.main.executablePath else {
      return nil
    }

    return FileManager.default.isExecutableFile(atPath: path) ? path : nil
  }

  /// Spawns a new session that survives the XPC service.
  func spawnDetached(executable: String, arguments: [String]) throws {
    var attributes: posix_spawnattr_t?
    let initResult = posix_spawnattr_init(&attributes)
    guard initResult == 0 else {
      throw NSError(domain: NSPOSIXErrorDomain, code: Int(initResult))
    }

    defer { posix_spawnattr_destroy(&attributes) }
    let flagsResult = posix_spawnattr_setflags(&attributes, Int16(POSIX_SPAWN_SETSID))
    guard flagsResult == 0 else {
      throw NSError(domain: NSPOSIXErrorDomain, code: Int(flagsResult))
    }

    let argv: [UnsafeMutablePointer<CChar>?] = ([executable] + arguments).map { strdup($0) } + [nil]
    defer { argv.forEach { free($0) } }

    // XPC_* variables would keep the child tied to this service
    let environment = ProcessInfo.processInfo.environment
      .filter { !$0.key.hasPrefix("XPC_") }
      .map { strdup("\($0.key)=\($0.value)") }

    let envp: [UnsafeMutablePointer<CChar>?] = environment + [nil]
    defer { environment.forEach { free($0) } }

    var pid: pid_t = 0
    let result = posix_spawn(&pid, executable, nil, &attributes, argv, envp)

    guard result == 0 else {
      throw NSError(domain: NSPOSIXErrorDomain, code: Int(result))
    }

    updaterLog.info("Installer started as pid \(pid)")
  }
}

private extension Error {
  /// Converts service errors for XPC transport.
  var transportable: any Error {
    NSError(
      domain: "app.cyan.markedit.updater",
      code: 0,
      userInfo: [NSLocalizedDescriptionKey: localizedDescription]
    )
  }
}
