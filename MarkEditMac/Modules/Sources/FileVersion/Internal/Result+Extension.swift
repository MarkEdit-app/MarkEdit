//
//  Result+Extension.swift
//
//  Created by cyan on 2024/10/17.
//

import AppKit
import DiffKit

extension Diff.Result {
  var textColor: NSColor {
    if added {
      return .addedText
    } else if removed {
      return .removedText
    } else {
      return .labelColor
    }
  }

  var backgroundColor: NSColor? {
    if added {
      return .addedBackground
    } else if removed {
      return .removedBackground
    } else {
      return nil
    }
  }
}

extension [Diff.Result] {
  var attributedText: NSAttributedString {
    let text = NSMutableAttributedString(string: "")
    for result in self {
      var attributes: [NSAttributedString.Key: Any] = [
        .foregroundColor: result.textColor,
        .font: Constants.font,
      ]

      if let backgroundColor = result.backgroundColor {
        attributes[.backgroundColor] = backgroundColor
      }

      text.append(NSAttributedString(string: result.value, attributes: attributes))
    }

    return text
  }

  var counterText: NSAttributedString {
    let text = NSMutableAttributedString(string: "")
    let addedCount = filter { $0.added }.count
    let removedCount = filter { $0.removed }.count

    if addedCount > 0 {
      text.append(NSAttributedString(
        string: " +\(addedCount) ",
        attributes: [
          .foregroundColor: NSColor.addedText,
          .backgroundColor: NSColor.addedBackground,
          .font: Constants.font,
        ]
      ))

      text.append(NSAttributedString(string: " "))
    }

    if removedCount > 0 {
      text.append(NSAttributedString(
        string: " -\(removedCount) ",
        attributes: [
          .foregroundColor: NSColor.removedText,
          .backgroundColor: NSColor.removedBackground,
          .font: Constants.font,
        ]
      ))
    }

    return text
  }
}

// MARK: - Private

private extension [Diff.Result] {
  enum Constants {
    static let font = NSFont.monospacedSystemFont(ofSize: 12)
  }
}
