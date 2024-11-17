//
//  ProcessInfo+Extension.swift
//
//  Created by cyan on 10/13/24.
//

import AppKit

public extension ProcessInfo {
  var semanticOSVer: String {
    let version = operatingSystemVersion
    return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
  }

  var userAgent: String {
    "macOS/\(semanticOSVer)"
  }
}
