//
//  HostBundle.swift
//
//  Created by cyan on 8/4/26.
//

import Foundation

/// The app an XPC service is embedded in, the only bundle the updater may replace.
public enum HostBundle {
  /// Resolves an embedded XPC service to its containing app bundle.
  public static func path(ofServiceAt serviceURL: URL) -> String? {
    let service = serviceURL.standardizedFileURL
    let services = service.deletingLastPathComponent()
    let contents = services.deletingLastPathComponent()
    let host = contents.deletingLastPathComponent()

    guard service.pathExtension == "xpc", host.pathExtension == "app",
          services.lastPathComponent == "XPCServices", contents.lastPathComponent == "Contents" else {
      return nil
    }

    let path = host.path(percentEncoded: false)
    return path.hasSuffix("/") ? String(path.dropLast()) : path
  }
}
