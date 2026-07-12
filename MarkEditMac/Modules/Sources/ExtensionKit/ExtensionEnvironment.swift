//
//  ExtensionEnvironment.swift
//
//  Created by cyan on 7/12/26.
//

import Foundation
import AppKitExtensions
import MarkEditKit

/// Injectable environment for ExtensionKit: filesystem locations and the app version.
///
/// Defaults match the sandboxed app; tests can point these at temporary directories.
public enum ExtensionEnvironment {
  /// Base directory holding extensions.json and the scripts/ folder.
  nonisolated(unsafe) public static var documentsDirectory = URL.documentsDirectory

  /// Base directory for the cached registry index.
  nonisolated(unsafe) public static var cachesDirectory = URL.cachesDirectory

  /// Running app version, used for minAppVersion checks.
  nonisolated(unsafe) public static var appVersion = Bundle.main.shortVersionString ?? "0.0.0"

  static var extensionsURL: URL {
    documentsDirectory
      .appending(path: "extensions.json", directoryHint: .notDirectory)
      .resolvingSymbolicLink
  }

  static var scriptsDirectory: URL {
    documentsDirectory
      .appending(path: "scripts", directoryHint: .isDirectory)
      .resolvingSymbolicLink
  }

  static var indexCacheDirectory: URL {
    cachesDirectory.appending(path: "Extensions", directoryHint: .isDirectory)
  }

#if DEBUG
  /// Folder scanned for a manual `mock-index.json` when testing the update flow.
  static var debugDirectory: URL {
    documentsDirectory
      .appending(path: "debug", directoryHint: .isDirectory)
      .resolvingSymbolicLink
  }
#endif
}
