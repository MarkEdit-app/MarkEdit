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

    let script: String
    if url.lastPathComponent.lowercased().hasPrefix("markedit-theme-") {
      script = applyThemePatch(contents: contents)
    } else {
      script = contents
    }

    return """
    (() => {
    /* Injected by MarkEdit */
    const __FILE_PATH__ = '\(filePath)';
    const module = { exports: {} };
    const exports = module.exports;

    /* User script */
    \(script)
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

// MARK: - Private

private extension EditorUserAsset {
  static func applyThemePatch(contents: String) -> String {
    if contents.contains("circularReferencePatched") {
      return contents
    }

    // [Revisit] Dirty patch for https://code.haverbeke.berlin/codemirror/dev/issues/1723
    //
    // theme.extension now refers to "this" (the theme object), creating a circular reference,
    // markedit-theming has the fix, but we need to patch existing themes too.
    //
    // Remove this after themes with the fix are widely available (circularReferencePatched = true).
    return contents.replacing(/\):"extension"in (.+?)\?/) { match in
      let theme = match.1
      return "):(\"extension\"in \(theme)&&\(theme).extension!==\(theme))?"
    }
  }
}
