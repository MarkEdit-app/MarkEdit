//
//  Helpers.swift
//
//  Created by cyan on 4/27/26.
//

import Foundation

/// Composes Markdown link/image syntax from raw label and target strings.
enum MarkdownLink {
  /// Emits `[label](target)`, or `![label](target)` when `isImage` is true.
  static func formatted(label: String, target: String, isImage: Bool) -> String {
    let prefix = isImage ? "!" : ""
    return "\(prefix)[\(escape(label: label))](\(encode(path: target)))"
  }

  /// Percent-encode each path segment independently so `/` separators are preserved.
  static func encode(path: String) -> String {
    let allowed = CharacterSet.urlPathAllowed.subtracting(CharacterSet(charactersIn: "()[] "))
    return path
      .split(separator: "/", omittingEmptySubsequences: false)
      .map { String($0).addingPercentEncoding(withAllowedCharacters: allowed) ?? String($0) }
      .joined(separator: "/")
  }

  /// Escape brackets in a Markdown link label.
  static func escape(label: String) -> String {
    label.replacingOccurrences(of: "[", with: "\\[")
      .replacingOccurrences(of: "]", with: "\\]")
  }
}
