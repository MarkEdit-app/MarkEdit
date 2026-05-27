//
//  EditorUserAsset.swift
//
//  Created by cyan on 5/26/26.
//

import Foundation

/**
 Wrappers for user-injected scripts and styles.
 */
public enum EditorUserAsset {
  /**
   Wrap a user JavaScript file for injection.
   */
  public static func script(for url: URL, contents: String) -> String {
    let escapes: [(from: String, to: String)] = [
      ("\\", "\\\\"),
      ("'", "\\'"),
      ("\n", "\\n"),
      ("\r", "\\r"),
      ("\u{2028}", "\\u2028"),
      ("\u{2029}", "\\u2029"),
    ]

    let filePath = escapes.reduce(url.path(percentEncoded: false)) { path, escape in
      path.replacingOccurrences(of: escape.from, with: escape.to)
    }

    return """
    (() => {
    /* Injected by MarkEdit */
    const __FILE_PATH__ = '\(filePath)';
    const module = { exports: {} };
    const exports = module.exports;

    /* User script */
    \(contents)
    })();
    """
  }

  /**
   Wrap a user CSS file for injection.
   */
  public static func style(for url: URL, contents: String) -> String {
    let comment = url.lastPathComponent.replacingOccurrences(of: "*/", with: "*\\/")
    return "<style>/* \(comment) */\n\(contents)\n</style>"
  }
}
