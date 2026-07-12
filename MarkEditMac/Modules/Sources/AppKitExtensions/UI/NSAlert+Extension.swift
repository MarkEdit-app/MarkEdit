//
//  NSAlert+Extension.swift
//
//  Created by cyan on 12/3/23.
//

import AppKit

public extension NSAlert {
  /**
   Drop-in replacement for `informativeText` with Markdown support.
   */
  var markdownBody: String? {
    get {
      objc_getAssociatedObject(self, &AssociatedObjects.markdownBody) as? String
    }
    set {
      objc_setAssociatedObject(
        self,
        &AssociatedObjects.markdownBody,
        newValue,
        objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )

      updateAccessoryView(with: newValue ?? "")
    }
  }
}

// MARK: - Private

private extension NSAlert {
  @MainActor
  private enum AssociatedObjects {
    static var markdownBody: UInt8 = 0
  }

  private enum Constants {
    static let fontSize: Double = 12
    static let contentWidth: Double = 220
    static let contentPadding: Double = 10
  }

  func updateAccessoryView(with markdown: String) {
    let textFont = NSFont.systemFont(ofSize: Constants.fontSize)
    let textColor = NSColor.labelColor

    let textView = NSTextView()
    textView.font = textFont
    textView.textColor = textColor
    textView.drawsBackground = false
    textView.isEditable = false

    let baseAttributes: [NSAttributedString.Key: Any] = [
      .font: textFont,
      .foregroundColor: textColor,
    ]

    let attributedText: NSAttributedString = {
      guard let data = markdown.data(using: .utf8), let string = try? NSAttributedString(
        markdown: data,
        options: .init(allowsExtendedAttributes: true, interpretedSyntax: .inlineOnlyPreservingWhitespace)
      ) else {
        return NSAttributedString(string: markdown, attributes: baseAttributes)
      }

      let parsed = NSMutableAttributedString(attributedString: string)
      parsed.styleMarkdown(baseAttributes: baseAttributes, font: textFont)
      return parsed
    }()

    let textStorage = textView.textStorage
    textStorage?.setAttributedString(attributedText)

    let contentSize = CGSize(width: Constants.contentWidth, height: 0)
    textView.frame = CGRect(origin: CGPoint(x: Constants.contentPadding, y: 0), size: contentSize)
    textView.sizeToFit()

    let wrapper = NSView(frame: textView.frame.insetBy(dx: -Constants.contentPadding, dy: 0))
    wrapper.addSubview(textView)
    accessoryView = wrapper
    layout()
  }
}

private extension NSMutableAttributedString {
  /// Applies the base attributes and resolves Markdown bold into a concrete font.
  ///
  /// TextKit doesn't render inlinePresentationIntent, so strong emphasis needs a real bold font.
  func styleMarkdown(baseAttributes: [NSAttributedString.Key: Any], font: NSFont) {
    let fullRange = NSRange(location: 0, length: length)
    addAttributes(baseAttributes, range: fullRange)

    enumerateAttribute(.inlinePresentationIntent, in: fullRange) { value, range, _ in
      let intent: InlinePresentationIntent
      if let value = value as? InlinePresentationIntent {
        intent = value
      } else if let value = value as? NSNumber {
        intent = InlinePresentationIntent(rawValue: value.uintValue)
      } else {
        intent = []
      }

      if intent.contains(.stronglyEmphasized) {
        addAttribute(.font, value: font.boldVariant, range: range)
      }
    }
  }
}
