//
//  Diff.swift
//
//  Created by cyan on 10/15/24.
//

import Foundation
import JavaScriptCore

/**
 Swift wrapper of [jsdiff](https://github.com/kpdecker/jsdiff).

 It implements the Myers diff algorithm, and our minimized version is just 8 KB.
 */
@MainActor
public enum Diff {
  public enum Mode: String, CaseIterable {
    case lines
    case words
    case chars
  }

  public struct Result {
    public let value: String
    public let added: Bool
    public let removed: Bool

    public init(value: String, added: Bool, removed: Bool) {
      self.value = value
      self.added = added
      self.removed = removed
    }
  }

  public static func compute(oldValue: String, newValue: String, mode: Mode) -> [Result] {
    let noDiff = {
      [Result(value: oldValue, added: false, removed: false)]
    }

    guard let util = context?.objectForKeyedSubscript("window") else {
      assertionFailure("Failed to get the diffUtil object")
      return noDiff()
    }

    guard let results = (util.invokeMethod(
      "diff\(mode.rawValue.capitalized)", // diffLines, diffWords, diffChars
      withArguments: [oldValue, newValue]
    )).toArray() as? [[String: Any]] else {
      assertionFailure("Failed to invoke the diff method")
      return noDiff()
    }

    return results.compactMap { result in
      guard let value = result["value"] as? String else {
        assertionFailure("Missing value from result: \(result)")
        return nil
      }

      return Result(
        value: value,
        added: result["added"] as? Bool == true,
        removed: result["removed"] as? Bool == true
      )
    }
  }

  // MARK: - Private

  private static let context: JSContext? = {
    let context = JSContext()
    assert(context != nil, "Failed to initiate JSContext")

    context?.evaluateScript("var window = {};\n" + {
      guard let url = Bundle.module.url(forResource: "diff", withExtension: "js") else {
        assertionFailure("Failed to load diff.js")
        return ""
      }

      guard let data = try? Data(contentsOf: url) else {
        assertionFailure("Failed to decode diff.js")
        return ""
      }

      return String(data: data, encoding: .utf8) ?? ""
    }())

    return context
  }()
}
