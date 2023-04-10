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

    // Instead of creating a new WebView, opening the link using the system default behavior.
    //
    // It's a local file when it starts with baseURL, replace it with folder path.
    if let url = URL(string: url.absoluteString.replacingOccurrences(of: EditorWebView.baseURL?.absoluteString ?? "", with: document?.baseURL?.absoluteString ?? "")) {
      NSWorkspace.shared.openOrReveal(url: url)
    }

    return nil
  }
}

// MARK: - EditorWebViewMenuDelegate

extension EditorViewController: EditorWebViewMenuDelegate {
  func editorWebView(_ sender: EditorWebView, didSelect menuAction: EditorWebViewMenuAction) {
    switch menuAction {
    case .findSelection:
      findSelection(self)
    case .selectAllOccurrences:
      selectAllOccurrences()
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

  func editorCoreTextDidChange(_ sender: EditorModuleCore) {
    document?.updateChangeCount(.changeDone)

    if findPanel.mode != .hidden {
      Task {
        if let count = try? await bridge.search.numberOfMatches() {
          updateTextFinderPanels(numberOfItems: count)
        }
      }
    }
  }

  func editorCore(
    _ sender: EditorModuleCore,
    selectionDidChange lineColumn: LineColumnInfo,
    contentEdited: Bool
  ) {
    statusView.updateLineColumn(lineColumn)
    layoutStatusView()

    if !contentEdited {
      cancelCompletion()
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

  func editorFindPanelDidPressTabKey(_ sender: EditorFindPanel) {
    replacePanel.textField.startEditing(in: view.window)
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

  func editorReplacePanelDidClickReplaceNext(_ sender: EditorReplacePanel) {
    replaceNextInTextFinder()
  }

  func editorReplacePanelDidClickReplaceAll(_ sender: EditorReplacePanel) {
    replaceAllInTextFinder()
  }
}
