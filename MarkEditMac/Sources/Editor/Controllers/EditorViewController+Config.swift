//
//  EditorViewController+Config.swift
//  MarkEditMac
//
//  Created by cyan on 1/28/23.
//

import AppKit
import AppKitControls
import MarkEditCore
import MarkEditKit

extension EditorViewController {
  func setTheme(_ theme: AppTheme) {
    updateWindowColors(theme)
    bridge.config.setTheme(name: theme.editorTheme)

    // It's possible to select a light theme for dark mode,
    // override the window appearance to keep consistent.
    let resolvedAppearance = theme.resolvedAppearance
    view.window?.appearance = resolvedAppearance

    // Also update windows that inherit appearance from the editor
    completionContext.appearance = resolvedAppearance
    NSApp.windows.compactMap { $0 as? GotoLineWindow }.forEach {
      $0.appearance = resolvedAppearance
    }
  }

  func setFontFamily(_ fontFamily: String) {
    bridge.config.setFontFamily(fontFamily: fontFamily)
  }

  func setFontSize(_ fontSize: Double) {
    bridge.config.setFontSize(fontSize: fontSize)
  }

  func setShowLineNumbers(enabled: Bool) {
    bridge.config.setShowLineNumbers(enabled: enabled)
  }

  func setShowActiveLineIndicator(enabled: Bool) {
    bridge.config.setShowActiveLineIndicator(enabled: enabled)
  }

  func setInvisiblesBehavior(behavior: EditorInvisiblesBehavior) {
    bridge.config.setInvisiblesBehavior(behavior: behavior)
  }

  func setShowSelectionStatus(enabled: Bool) {
    statusView.isHidden = !enabled
  }

  func setTypewriterMode(enabled: Bool) {
    bridge.config.setTypewriterMode(enabled: enabled)
  }

  func setFocusMode(enabled: Bool) {
    bridge.config.setFocusMode(enabled: enabled)
  }

  func setLineWrapping(enabled: Bool) {
    bridge.config.setLineWrapping(enabled: enabled)
  }

  func setLineHeight(_ lineHeight: Double) {
    bridge.config.setLineHeight(lineHeight: lineHeight)
  }

  func setDefaultLineBreak(_ lineBreak: String?) {
    bridge.config.setDefaultLineBreak(lineBreak: lineBreak)
  }

  func setTabKeyBehavior(_ behavior: TabKeyBehavior) {
    bridge.config.setTabKeyBehavior(behavior: behavior)
  }

  func setIndentUnit(_ unit: IndentUnit) {
    bridge.config.setIndentUnit(unit: unit.characters)
  }

  func setSuggestWhileTyping(enabled: Bool) {
    bridge.config.setSuggestWhileTyping(enabled: enabled)
  }
}
