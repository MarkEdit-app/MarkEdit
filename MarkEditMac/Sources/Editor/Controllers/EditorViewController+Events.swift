//
//  EditorViewController+Events.swift
//  MarkEditMac
//
//  Created by cyan on 2024/3/28.
//

import AppKit
import MarkEditKit

extension EditorViewController {
  func addLocalMonitorForEvents() {
    NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
      // Press backspace or option to cancel the correction indicator,
      // it ensures a smoother word completion experience.
      if event.keyCode == .kVK_Delete || event.keyCode == .kVK_Option, let self {
        NSSpellChecker.shared.declineCorrectionIndicator(for: self.webView)
      }

      // Press F to potentially change the find mode or switch focus between two fields
      if event.keyCode == .kVK_ANSI_F, let self {
        self.updateTextFinderModeIfNeeded(event)
      }

      // Press tab key
      if event.keyCode == .kVK_Tab, let self {
        // It looks like contenteditable works differently compared to NSTextView,
        // the first responder must be self.view to handle tab switching.
        if event.modifierFlags.contains(.control) {
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
      }

      return event
    }
  }
}
