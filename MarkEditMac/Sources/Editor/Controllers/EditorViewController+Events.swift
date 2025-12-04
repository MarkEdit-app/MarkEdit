//
//  EditorViewController+Events.swift
//  MarkEditMac
//
//  Created by cyan on 3/28/24.
//

import AppKit
import MarkEditKit

extension EditorViewController {
  func addLocalMonitorForEvents() {
    localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
      // Handle events only when view.window is the key window
      guard let window = self?.view.window, window.isKeyWindow else {
        return event
      }

      // Press backspace or option to cancel the correction indicator,
      // it ensures a smoother word completion experience.
      if event.keyCode == .kVK_Delete || event.keyCode == .kVK_Option, let self {
        NSSpellChecker.shared.declineCorrectionIndicator(for: self.webView)
      }

      // Press right option
      if event.keyCode == .kVK_RightOption, event.deviceIndependentFlags == .option, let self {
        if NSSpellChecker.hasVisibleCorrectionPanel {
          // Accept auto correction
          NSSpellChecker.shared.dismissCorrectionIndicator(for: self.webView)
        } else {
          // Accept inline prediction without adding any punctuations
          NSSpellChecker.shared.acceptWebKitInlinePrediction(
            view: self.webView,
            bridge: self.bridge.completion
          )
        }
      }

      // Press tab key
      if event.keyCode == .kVK_Tab, let self {
        // It looks like contenteditable works differently compared to NSTextView,
        // the first responder must be self.view to handle tab switching.
        if event.modifierFlags.contains(.control), !NSApp.isFullKeyboardAccessEnabled {
          self.view.window?.makeFirstResponder(self.view)
        }

        // Accept the first spellcheck suggestion
        NSSpellChecker.shared.dismissCorrectionIndicator(for: self.webView)
      }

      // Press Option-Command-I to show the inspector
      if event.keyCode == .kVK_ANSI_I,
         event.deviceIndependentFlags == [.option, .command],
         let self, self.view.window != nil {
        self.webView.showInspector()
        return nil
      }

      // Press Fn-Control-F to fill the window, see #1167
      if event.keyCode == .kVK_ANSI_F, event.deviceIndependentFlags == [.function, .control] {
        NSApp.sendAction(sel_getUid("_zoomFill:"), to: nil, from: nil)
        return nil
      }

      // Press F to potentially change the find mode or switch focus between two fields
      if event.keyCode == .kVK_ANSI_F, let self, self.updateTextFinderModeIfNeeded(event) {
        return nil
      }

      // (Alternatives) F3 to find next, Shift-F3 to find previous
      if event.keyCode == .kVK_F3, let self {
        if event.deviceIndependentFlags == .shift {
          self.findPreviousInTextFinder()
        } else {
          self.findNextInTextFinder()
        }
        return nil
      }

      return event
    }
  }
}
