//
//  EditorTextInput.swift
//  MarkEditMac
//
//  Created by cyan on 8/23/23.
//

import AppKit

enum EditorTextAction {
  case undo
  case redo
}

/**
 Abstraction of text input actions for `NSText` and `EditorWebView`.

 For `NSText`, extend AppKit to provide an implementation.

 For `EditorWebView`, delegate actions to controller that has access to the bridge.
 */
@MainActor
protocol EditorTextInput {
  func performTextAction(_ action: EditorTextAction, sender: Any?)
}

extension NSText: EditorTextInput {
  func performTextAction(_ action: EditorTextAction, sender: Any?) {
    switch action {
    case .undo:
      undoManager?.undo()
    case .redo:
      undoManager?.redo()
    }
  }
}

extension EditorWebView: EditorTextInput {
  func performTextAction(_ action: EditorTextAction, sender: Any?) {
    actionDelegate?.editorWebView(self, didPerform: action, sender: sender)
  }
}
