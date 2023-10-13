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
  /**
   For macOS Sonoma and higher, manage inline prediction features in the app.

   We need this because changing `allowsInlinePredictions` in `WKWebViewConfiguration` won't work without creating a new `WKWebView`.

   Internally, [WebKit](https://github.com/WebKit/WebKit/blob/main/Source/WebKit/UIProcess/mac/WebViewImpl.mm) checks the `isAutomaticInlineCompletionEnabled` SPI, which can be swizzled.

   If `isAutomaticInlineCompletionEnabled` exists, we swizzle it and return the value set by the user and make the configuration always true. Otherwise, we just set the configuration to the value set by the user.
   */
  enum InlineCompletion {
    static var webKitEnabled: Bool {
      if NSSpellChecker.supportsInlineCompletion {
        return true
      } else {
        return AppPreferences.Assistant.inlinePredictions
      }
    }

    static var spellCheckerEnabled = AppPreferences.Assistant.inlinePredictions
    fileprivate static let spellCheckerSelector = sel_getUid("isAutomaticInlineCompletionEnabled")
  }

  static let swizzleInlineCompletionEnabledOnce: () = {
    guard supportsInlineCompletion else {
      return
    }

    NSSpellChecker.exchangeClassMethods(
      originalSelector: InlineCompletion.spellCheckerSelector,
      swizzledSelector: #selector(getter: swizzled_isAutomaticInlineCompletionEnabled)
    )
  }()

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
  static var supportsInlineCompletion: Bool {
    guard #available(macOS 14.0, *) else {
      return false
    }

    guard responds(to: InlineCompletion.spellCheckerSelector) else {
      Logger.assertFail("The isAutomaticInlineCompletionEnabled selector was changed")
      return false
    }

    return true
  }

  @objc static var swizzled_isAutomaticInlineCompletionEnabled: Bool {
    InlineCompletion.spellCheckerEnabled
  }

  @objc func swizzled_showCorrectionIndicator(
    of type: NSSpellChecker.CorrectionIndicatorType,
    primaryString: String,
    alternativeStrings: [String],
    forStringIn rectOfTypedString: CGRect,
    view: NSView,
    completionHandler completionBlock: ((String?) -> Void)? = nil
  ) {
    let dummyAction = {
      // We previously was able to just ignore the call,
      // since macOS 14, it hangs working with inline predictions.
      if #available(macOS 14.0, *) {
        self.swizzled_showCorrectionIndicator(
          of: type,
          primaryString: primaryString,
          alternativeStrings: [],
          forStringIn: CGRect(x: 1e5, y: 1e5, width: 0, height: 0), // Insane rect to make it invisible
          view: view,
          completionHandler: completionBlock
        )
      }
    }

    // When the option key is held,
    // the user may press esc to show text completion.
    guard !NSApplication.shared.optionKeyIsPressed else {
      return dummyAction()
    }

    // We prefer completion over correction,
    // when suggestWhileTyping is enabled we don't show correction indicators.
    guard !AppPreferences.Assistant.suggestWhileTyping else {
      return dummyAction()
    }

    // We also want to avoid the overlap of the two panels
    guard !NSApp.windows.contains(where: { $0.isVisible && $0 is TextCompletionPanelProtocol }) else {
      return dummyAction()
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
