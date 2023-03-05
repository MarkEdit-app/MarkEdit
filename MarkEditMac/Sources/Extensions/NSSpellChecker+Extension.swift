//
//  NSSpellChecker+Extension.swift
//  MarkEditMac
//
//  Created by cyan on 2/28/23.
//

import AppKit

extension NSSpellChecker {
  static let swizzleCorrectionIndicatorOnce: () = {
    NSSpellChecker.exchangeInstanceMethods(
      originalSelector: #selector(showCorrectionIndicator(of:primaryString:alternativeStrings:forStringIn:view:completionHandler:)),
      swizzledSelector: #selector(swizzled_showCorrectionIndicator(of:primaryString:alternativeStrings:forStringIn:view:completionHandler:))
    )
  }()
}

// MARK: - Private

private extension NSSpellChecker {
  @objc private func swizzled_showCorrectionIndicator(
    of type: NSSpellChecker.CorrectionIndicatorType,
    primaryString: String,
    alternativeStrings: [String],
    forStringIn rectOfTypedString: CGRect,
    view: NSView,
    completionHandler completionBlock: ((String?) -> Void)? = nil
  ) {
    // We prefer completion over correction,
    // when suggestWhileTyping is enabled we don't show correction indicators.
    guard !AppPreferences.Assistant.suggestWhileTyping else {
      return
    }

    swizzled_showCorrectionIndicator(
      of: type,
      primaryString: primaryString,
      alternativeStrings: alternativeStrings,
      forStringIn: rectOfTypedString,
      view: view,
      completionHandler: completionBlock
    )
  }
}
