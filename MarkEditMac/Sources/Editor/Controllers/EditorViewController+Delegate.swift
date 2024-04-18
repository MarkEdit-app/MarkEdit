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

// MARK: - WKUIDelegate

extension EditorViewController: WKUIDelegate {
  nonisolated func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
    guard let url = navigationAction.request.url else {
      return nil
    }

    Task { @MainActor in
      // Instead of creating a new WebView, opening the link using the system default behavior.
      //
      // It's a local file when it starts with baseURL, replace it with folder path.
      if let url = URL(string: url.absoluteString.replacingOccurrences(of: EditorWebView.baseURL?.absoluteString ?? "", with: document?.baseURL?.absoluteString ?? "")) {
        NSWorkspace.shared.openOrReveal(url: url)
      }
    }

    return nil
  }
}

// MARK: - EditorWebViewActionDelegate

extension EditorViewController: EditorWebViewActionDelegate {
  func editorWebViewIsReadOnlyMode(_ webView: EditorWebView) -> Bool {
    isReadOnlyMode
  }

  func editorWebViewHasTextSelection(_ webView: EditorWebView) -> Bool {
    hasTextSelection
  }

  func editorWebViewSearchOperationsMenuItem(_ webView: EditorWebView) -> NSMenuItem? {
    searchOperationsMenuItem
  }

  func editorWebViewResignFirstResponder(_ webView: EditorWebView) {
    // resignFirstResponder is called when webView.isHidden = true
    guard hasFinishedLoading && !webView.isHidden else {
      return
    }

    bridge.search.updateHasSelection()
  }

  func editorWebView(_ webView: EditorWebView, mouseDownWith event: NSEvent) {
    cancelCompletion()
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

  func editorCoreBackgroundColorDidChange(_ sender: EditorModuleCore, color: UInt32) {
    webBackgroundColor = NSColor(hexCode: color)
    updateWindowColors(.current)
  }

  func editorCoreViewportScaleDidChange(_ sender: EditorModuleCore) {
    // Remove all floating UI elements since view coordinates are changed
    removeFloatingUIElements()
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

    // The content is edited once contentEdited is true, it cannot go back
    hasBeenEdited = hasBeenEdited || contentEdited
    hasTextSelection = !selectedLineColumn.selectionText.isEmpty

    // Only update the dirty state when it's edited,
    // the app can launch with an unsaved state (e.g., force quit), it should remain dirty.
    if hasBeenEdited {
      // The content is always dirty if it was edited as a temporary document
      document?.markContentDirty(isDirty || (hasBeenEdited && document?.fileURL == nil))
    }
  }

  func editorCoreContentHeightDidChange(_ sender: EditorModuleCore, bottomPanelHeight: Double) {
    self.bottomPanelHeight = bottomPanelHeight
    self.layoutStatusView()
  }

  func editorCoreContentOffsetDidChange(_ sender: EditorModuleCore) {
    // Remove all floating UI elements since view coordinates are changed
    removeFloatingUIElements()
  }

  func editorCoreCompositionEnded(_ sender: EditorModuleCore, selectedLineColumn: LineColumnInfo) {
    statusView.updateLineColumn(selectedLineColumn)
    layoutStatusView()
  }

  func editorCoreLinkClicked(_ sender: EditorModuleCore, link: String) {
    let (url, isFile): (URL?, Bool) = {
      // Try url with schemes first, e.g., https://github.com
      if let url = URL(string: link), url.scheme?.isEmpty == false {
        return (url, false)
      }

      // Fallback to local files, e.g., file:///Users/cyan/...
      return (document?.baseURL?.appending(path: link.removingPercentEncoding ?? link), true)
    }()

    // Open or reveal the url
    if let url, NSWorkspace.shared.openOrReveal(url: url) {
      return
    }

    // Failed, fallback to opening the document folder
    if isFile, let baseURL = document?.baseURL {
      NSWorkspace.shared.activateFileViewerSelecting([baseURL])
      return
    }

    // Failed eventually
    Logger.log(.info, "Failed to open link: \(link)")
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
  func editorPreview(_ sender: EditorModulePreview, show code: String, type: PreviewType, rect: CGRect) {
    showPreview(code: code, type: type, rect: rect)
  }
}

// MARK: - EditorModuleUIDelegate

extension EditorViewController: EditorModuleUIDelegate {
  func editorUI(_ sender: EditorModuleUI, addMainMenuItems items: [(String, WebMenuItem)]) {
    addMainMenuItems(items: items)
  }

  func editorUI(_ sender: EditorModuleUI, showContextMenu items: [WebMenuItem], location: WebPoint) {
    showContextMenu(items: items, location: location.cgPoint)
  }

  func editorUI(
    _ sender: EditorModuleUI,
    alertWith title: String?,
    message: String?,
    buttons: [String]?
  ) -> Int {
    let response = showAlert(title: title, message: message, buttons: buttons)
    return response.rawValue - NSApplication.ModalResponse.alertFirstButtonReturn.rawValue
  }

  func editorUI(_ sender: EditorModuleUI, showTextBox title: String?, placeholder: String?, defaultValue: String?) -> String? {
    showTextBox(title: title, placeholder: placeholder, defaultValue: defaultValue)
  }
}

// MARK: - EditorFindPanelDelegate

extension EditorViewController: EditorFindPanelDelegate {
  func editorFindPanel(_ sender: EditorFindPanel, modeDidChange mode: EditorFindMode) {
    updateTextFinderMode(mode, explicitly: true)
  }

  func editorFindPanel(_ sender: EditorFindPanel, searchTermDidChange searchTerm: String) {
    updateTextFinderQuery()
  }

  func editorFindPanelOperationsMenuItem(_ sender: EditorFindPanel) -> NSMenuItem? {
    searchOperationsMenuItem
  }

  func editorFindPanelDidChangeOptions(_ sender: EditorFindPanel) {
    updateTextFinderQuery()
  }

  func editorFindPanelDidPressTabKey(_ sender: EditorFindPanel, isBacktab: Bool) {
    if isBacktab {
      startTextEditing()
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
      startTextEditing()
    }
  }

  func editorReplacePanelDidClickReplaceNext(_ sender: EditorReplacePanel) {
    replaceNextInTextFinder()
  }

  func editorReplacePanelDidClickReplaceAll(_ sender: EditorReplacePanel) {
    replaceAllInTextFinder()
  }
}
