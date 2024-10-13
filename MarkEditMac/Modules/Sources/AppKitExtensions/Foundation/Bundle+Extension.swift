//
//  Bundle+Extension.swift
//
//  Created by cyan on 11/1/23.
//

import Foundation

public extension Bundle {
  var shortVersionString: String? {
    infoDictionary?["CFBundleShortVersionString"] as? String
  }

  var userAgent: String {
    "MarkEdit/\(shortVersionString ?? "0.0.0")"
  }
}
