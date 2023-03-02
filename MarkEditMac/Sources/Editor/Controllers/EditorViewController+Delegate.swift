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

    // Instead of creating a new WebView, opening the link in the system default browser
    if url.absoluteString.contains("grammarly") {
      Grammarly.shared.startOAuth(url: url, bridge: bridge.grammarly)
    } else {
      NSWorkspace.shared.open(url)
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

  func editorCore(_ sender: EditorModuleCore, selectionDidChange lineColumn: LineColumnInfo) {
    statusView.updateLineColumn(lineColumn)
    layoutStatusView()
    updateCompletionPanel(isVisible: false)
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

  func editorCompletionCommit(_ sender: EditorModuleCompletion) {
    commitCompletion()
  }

  func editorCompletionSelectPrevious(_ sender: EditorModuleCompletion) {
    selectPreviousCompletion()
  }

  func editorCompletionSelectNext(_ sender: EditorModuleCompletion) {
    selectNextCompletion()
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
