//
//  NSSpellChecker+Extension.swift
//
//  Created by cyan on 7/12/26.
//

import AppKit

public extension NSSpellChecker {
  func declineCorrectionIndicator(for view: NSView) {
    // It's insane that this method is not public,
    // "dismissCorrectionIndicatorForView:" accepts the proposal, which is not what we want.
    let selector = sel_getUid("cancelCorrectionIndicatorForView:")
    if responds(to: selector) {
      perform(selector, with: view)
    } else {
      assertionFailure("Failed to call cancelCorrectionIndicatorForView, selector was changed")
    }
  }
}
