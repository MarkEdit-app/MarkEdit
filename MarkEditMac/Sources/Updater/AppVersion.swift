//
//  AppVersion.swift
//  MarkEditMac
//
//  Created by cyan on 11/1/23.
//

import AppKitExtensions
import Foundation

/**
 [GitHub Releases API](https://api.github.com/repos/MarkEdit-app/MarkEdit/releases/latest)
 */
struct AppVersion: Decodable {
  private static let universalArchive = "UpdateArchive.zip"
  private static let appleSiliconArchive = "UpdateArchive-arm64.zip"

  struct Asset: Decodable {
    let name: String
    let browserDownloadUrl: String
  }

  let name: String
  let body: String
  let htmlUrl: String
  let assets: [Asset]?

  /**
   Returns true when this version was released to MAS.

   The logic here is, versions up to 1.13.4 were released to MAS, they don't have a meaningful release name. We can use this as a sign to differentiate MAS release and GitHub release.

   For example: https://github.com/MarkEdit-app/MarkEdit/releases/tag/v1.13.4-rc1 (name is empty)
   */
  var releasedToMAS: Bool {
    name.isEmpty
  }

  /**
    Whether this release is newer than the running app.
   */
  var isCompatible: Bool {
    name.compare(Bundle.main.shortVersionString, options: .numeric) == .orderedDescending
  }

  /**
    Returns the in-app update archive for the installed architecture.
   */
  var updateArchive: Asset? {
    let universal = assets?.first { $0.name == Self.universalArchive }

    guard Bundle.main.isAppleSiliconOnly else {
      return universal
    }

    return assets?.first { $0.name == Self.appleSiliconArchive } ?? universal
  }
}

/**
 ReleaseInfo.json added to GitHub release assets.

 It typically contains extra information for better updating experience.
 */
struct ReleaseInfo: Decodable {
  let minOSVer: String
}
