//
//  StagingLocation.swift
//
//  Created by cyan on 8/4/26.
//

import Foundation

/// Updater staging directory naming rules.
public enum StagingLocation {
  public static let prefix = ".markedit-update-"

  /// Returns a parent directory whose name has the staging prefix.
  public static func directory(of stagedPath: String) -> URL? {
    let staging = URL(fileURLWithPath: stagedPath).standardizedFileURL.deletingLastPathComponent()
    return staging.lastPathComponent.hasPrefix(prefix) ? staging : nil
  }
}
