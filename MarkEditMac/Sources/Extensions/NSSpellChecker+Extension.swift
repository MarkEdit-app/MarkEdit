//
//  NSSpellChecker+Extension.swift
//  MarkEditMac
//
//  Created by cyan on 2/28/23.
//

import AppKit
import MarkEditKit
import TextCompletion

/**
 NSSpellChecker is pretty much a black box, this extension uses runtime skills to hack it around.
 */
extension NSSpellChecker {
  static let swizzleCorrectionIndicatorOnce: () = {
    NSSpellChecker.exchangeInstanceMethods(
      originalSelector: #selector(showCorrectionIndicator(of:primaryString:alternativeStrings:forStringIn:view:completionHandler:)),
      swizzledSelector: #selector(swizzled_showCorrectionIndicator(of:primaryString:alternativeStrings:forStringIn:view:completionHandler:))
    )
  }()

  func declineCorrectionIndicator(for view: NSView) {
    // It's insane that this method is not public,
    // "dismissCorrectionIndicatorForView:" accepts the proposal, which is not what we want.
    let selector = sel_getUid("cancelCorrectionIndicatorForView:")
    if responds(to: selector) {
      perform(selector, with: view)
    } else {
      Logger.assertFail("Failed to call cancelCorrectionIndicatorForView, selector was changed")
    }
  }
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

    // We also want to avoid the overlap of the two panels
    guard !NSApp.windows.contains(where: { $0 is TextCompletionPanelProtocol }) else {
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
