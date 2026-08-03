//
//  UpdateInstalling.swift
//  UpdateInstaller
//
//  Created by cyan on 8/2/26.
//

import Foundation

/**
 XPC interface between the sandboxed app and its updater service.
 */
@objc protocol UpdateInstalling {
  /// Extracts `archivePath` into a staging directory and verifies it against the app to replace.
  func prepareUpdate(archivePath: String) async throws -> String

  /// Spawns the detached installer that swaps `stagedPath` in once `processIdentifier` exits.
  func commitUpdate(
    stagedPath: String,
    processIdentifier: Int32,
    relaunch: Bool,
    reply: @escaping (String?) -> Void
  )

  /// Deletes a staged update that will never be installed.
  func discardUpdate(stagedPath: String) async throws
}
