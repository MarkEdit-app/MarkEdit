//
//  EditorViewController+Delegate.swift
//  MarkEditMac
//
//  Created by cyan on 12/27/22.
//

import AppKit
import WebKit
import MarkEditCore
import MarkEditKit
import Proofing

// MARK: - WKUIDelegate

extension EditorViewController: WKUIDelegate {
  func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
    guard let url = navigationAction.request.url else {
      return nil
    }

    // Capture the bridge for Grammarly OAuth requests
    if url.absoluteString.contains("grammarly.com") {
      Grammarly.shared.startOAuth(bridge: bridge.grammarly)
    }

    return nil
  }
}

// MARK: - EditorWebViewActionDelegate

extension EditorViewController: EditorWebViewActionDelegate {
  func editorWebViewIsReadOnly(_ webView: EditorWebView) -> Bool {
    isReadOnly
  }

  func editorWebView(_ webView: EditorWebView, didSelect menuAction: EditorWebViewMenuAction) {
    switch menuAction {
    case .findSelection:
      findSelection(self)
    case .selectAllOccurrences:
      selectAllOccurrences()
    }
  }

  func editorWebView(
    _ webView: EditorWebView,
    didPerform textAction: EditorTextAction,
    sender: Any?
  ) {
    switch textAction {
    case .undo:
      bridge.history.undo()
    case .redo:
      bridge.history.redo()
    case .selectAll:
      bridge.selection.selectAll()
    case .paste:
      NSPasteboard.general.sanitize()
      NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: nil)
    }
  }
}

// MARK: - EditorModuleCoreDelegate

extension EditorViewController: EditorModuleCoreDelegate {
  func editorCoreWindowDidLoad(_ sender: EditorModuleCore) {
    hasFinishedLoading = true
    resetEditor()

    // We only need the indicator for cold launch because it's slower
    NSAnimationContext.runAnimationGroup { _ in
      loadingIndicator.animator().alphaValue = 0
    } completionHandler: {
      self.loadingIndicator.removeFromSuperview()
    }

    loadingIndicator.scaleTo(2.0)
  }

  func editorCoreViewportScaleDidChange(_ sender: EditorModuleCore) {
    // Viewport scale changed, perform cancel where we dismiss panels and popovers
    cancelOperation(sender)
  }

  func editorCoreViewDidUpdate(
    _ sender: EditorModuleCore,
    contentEdited: Bool,
    compositionEnded: Bool,
    isDirty: Bool,
    selectedLineColumn: LineColumnInfo
  ) {
    if compositionEnded {
      // Update the selection only when composition ended,
      // to avoid flickers caused by false positives of text selections,
      // i.e., marked text is considered "selected".
      //
      // This is meaningful especially for input methods like Pinyin.
      editorCoreCompositionEnded(sender, selectedLineColumn: selectedLineColumn)
    }

    if contentEdited {
      document?.markContentDirty(isDirty)

      if findPanel.mode != .hidden {
        Task {
          if let count = try? await bridge.search.numberOfMatches() {
            updateTextFinderPanels(numberOfItems: count)
          }
        }
      }
    } else {
      cancelCompletion()
    }
  }

  func editorCoreCompositionEnded(_ sender: EditorModuleCore, selectedLineColumn: LineColumnInfo) {
    statusView.updateLineColumn(selectedLineColumn)
    layoutStatusView()
  }

  func editorCoreLinkClicked(_ sender: EditorModuleCore, link: String) {
    guard let baseURL = document?.baseURL else {
      return Logger.assertFail("The document should always have a baseURL")
    }

    let url = {
      // Try url with schemes first, e.g., https://markedit.app
      if let url = URL(string: link), url.scheme?.isEmpty == false {
        return url
      }

      // Fallback to local files, e.g., file:///Users/cyan/...
      return baseURL.appendingPathComponent(link.removingPercentEncoding ?? link)
    }()

    // Open or reveal, fallback to opening the document folder if failed
    if !NSWorkspace.shared.openOrReveal(url: url) {
      NSWorkspace.shared.activateFileViewerSelecting([baseURL])
    }
  }
}

// MARK: - EditorModuleCompletionDelegate

extension EditorViewController: EditorModuleCompletionDelegate {
  func editorCompletion(
    _ sender: EditorModuleCompletion,
    request prefix: String,
    anchor: TextTokenizeAnchor,
    partialRange: NSRange,
    tokenizedWords: [String]
  ) {
    requestCompletions(
      prefix: prefix,
      anchor: anchor,
      partialRange: partialRange,
      tokenizedWords: tokenizedWords
    )
  }

  func editorCompletionTokenizeWholeDocument(_ sender: EditorModuleCompletion) -> Bool {
    AppPreferences.Assistant.wordsInDocument
  }

  func editorCompletionDidCommit(_ sender: EditorModuleCompletion) {
    commitCompletion()
  }

  func editorCompletionDidCancel(_ sender: EditorModuleCompletion) {
    cancelCompletion()
  }

  func editorCompletionDidSelectPrevious(_ sender: EditorModuleCompletion) {
    completionContext.selectPrevious()
  }

  func editorCompletionDidSelectNext(_ sender: EditorModuleCompletion) {
    completionContext.selectNext()
  }

  func editorCompletionDidSelectTop(_ sender: EditorModuleCompletion) {
    completionContext.selectTop()
  }

  func editorCompletionDidSelectBottom(_ sender: EditorModuleCompletion) {
    completionContext.selectBottom()
  }
}

// MARK: - EditorModulePreviewDelegate

extension EditorViewController: EditorModulePreviewDelegate {
  func editorPreview(_ sender: NativeModulePreview, show code: String, type: PreviewType, rect: CGRect) {
    showPreview(code: code, type: type, rect: rect)
  }
}

// MARK: - EditorFindPanelDelegate

extension EditorViewController: EditorFindPanelDelegate {
  func editorFindPanel(_ sender: EditorFindPanel, modeDidChange mode: EditorFindMode) {
    updateTextFinderMode(mode)
  }

  func editorFindPanel(_ sender: EditorFindPanel, searchTermDidChange searchTerm: String) {
    updateTextFinderQuery()
  }

  func editorFindPanelDidChangeOptions(_ sender: EditorFindPanel) {
    updateTextFinderQuery()
  }

  func editorFindPanelDidPressTabKey(_ sender: EditorFindPanel, isBacktab: Bool) {
    if isBacktab {
      startWebViewEditing()
    } else {
      replacePanel.textField.startEditing(in: view.window)
    }
  }

  func editorFindPanelDidClickNext(_ sender: EditorFindPanel) {
    findNextInTextFinder()
  }

  func editorFindPanelDidClickPrevious(_ sender: EditorFindPanel) {
    findPreviousInTextFinder()
  }
}

// MARK: - EditorReplacePanelDelegate

extension EditorViewController: EditorReplacePanelDelegate {
  func editorReplacePanel(_ sender: EditorReplacePanel, replacementDidChange replacement: String) {
    updateTextFinderQuery()
  }

  func editorReplacePanelDidPressTabKey(_ sender: EditorReplacePanel, isBacktab: Bool) {
    if isBacktab {
      findPanel.searchField.startEditing(in: view.window)
    } else {
      startWebViewEditing()
    }
  }

  func editorReplacePanelDidClickReplaceNext(_ sender: EditorReplacePanel) {
    replaceNextInTextFinder()
  }

  func editorReplacePanelDidClickReplaceAll(_ sender: EditorReplacePanel) {
    replaceAllInTextFinder()
  }
}
