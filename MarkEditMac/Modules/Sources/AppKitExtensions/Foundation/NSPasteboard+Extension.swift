//
//  NSPasteboard+Extension.swift
//
//  Created by cyan on 1/4/23.
//

import AppKit

public extension NSPasteboard {
  var string: String? {
    string(forType: .string)
  }

  var url: String? {
    guard let string else {
      return string(forType: .URL)
    }

    return NSDataDetector.extractURL(from: string)
  }

  func overwrite(string: String?) {
    clearContents()

    if let string {
      setString(string, forType: .string)
    }
  }

  func sanitizeURLs() {
    // Handle the case where a link is only copied to "public.url",
    // for example, copying the link generated for iCloud Collaborate.
    if string?.isEmpty ?? true, let url = string(forType: .URL), !url.isEmpty {
      declareTypes([.string, .URL], owner: nil)
      setString(url, forType: .string)
      setString(url, forType: .URL)
    }
  }
}
