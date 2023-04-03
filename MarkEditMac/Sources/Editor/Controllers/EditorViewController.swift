//
//  EditorViewController.swift
//  MarkEditMac
//
//  Created by cyan on 12/12/22.

import AppKit
import AppKitControls
import WebKit
import MarkEditCore
import MarkEditKit
import Proofing
import TextCompletion

final class EditorViewController: NSViewController {
  var hasFinishedLoading = false
  var hasUnfinishedAnimations = false
  var safeAreaObservation: NSKeyValueObservation?

  var editorText: String? {
    get async {
      guard hasFinishedLoading else {
        return nil
      }

      return try? await bridge.core.getEditorText()
    }
  }

  lazy var bridge = WebModuleBridge(
    webView: webView
  )

  var document: EditorDocument? {
    representedObject as? EditorDocument
  }

  private(set) lazy var findPanel = {
    let panel = EditorFindPanel()
    panel.delegate = self
    return panel
  }()

  private(set) lazy var replacePanel = {
    let panel = EditorReplacePanel()
    panel.delegate = self
    return panel
  }()

  private(set) lazy var panelDivider = {
    DividerView()
  }()

  private(set) lazy var statusView = {
    let view = EditorStatusView { [weak self] in
      self?.showGotoLineWindow(nil)
    }

    view.isHidden = !AppPreferences.Editor.showSelectionStatus
    return view
  }()

  private(set) lazy var focusTrackingView = {
    FocusTrackingView()
  }()

  private(set) lazy var webView: WKWebView = {
    let modules = NativeModules(modules: [
      EditorModuleCore(delegate: self),
      EditorModuleCompletion(delegate: self),
      EditorModulePreview(delegate: self),
      EditorModuleTokenizer(),
    ])

    let handler = EditorMessageHandler(modules: modules) { [weak self] in
      self?.webView
    }

    let controller = WKUserContentController()
    controller.addScriptMessageHandler(handler, contentWorld: .page, name: "bridge")

    let config: WKWebViewConfiguration = .newConfig()
    config.processPool = EditorReusePool.shared.processPool
    config.userContentController = controller

    let webView = EditorWebView(frame: .zero, configuration: config)
    webView.uiDelegate = self
    webView.menuDelegate = self

    if #available(macOS 13.3, *) {
    #if compiler(>=5.8) // Xcode 14.3
      webView.isInspectable = true
    #else
      if webView.responds(to: sel_getUid("isInspectable")) {
        webView.setValue(true, forKey: "inspectable")
      }
    #endif
    }

    let html = [
      AppPreferences.editorConfig.toHtml,
      EditorCustomization.style.contents,
      EditorCustomization.script.contents,
    ].joined(separator: "\n\n")

    // Non-nil baseURL is required by Grammarly and opening local files
    webView.loadHTMLString(html, baseURL: EditorWebView.baseURL)
    return webView
  }()

  private(set) lazy var spellChecker = {
    NSSpellChecker()
  }()

  private(set) lazy var completionContext = {
    TextCompletionContext(
      localize: TextCompletionLocalizable(selectedHint: Localized.General.selected)
    ) { [weak self] in
      self?.commitCompletion()
    }
  }()

  init() {
    super.init(nibName: nil, bundle: nil)
    _ = self.webView // Pre-load
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    setUp()
  }

  override func viewWillAppear() {
    super.viewWillAppear()
    configureToolbar()
  }

  override func viewDidLayout() {
    super.viewDidLayout()
    guard !hasUnfinishedAnimations else {
      return
    }

    layoutPanels()
    layoutWebView()
    layoutStatusView()
  }

  override func mouseMoved(with event: NSEvent) {
    super.mouseMoved(with: event)
    handleMouseMoved(event)
  }

  override func complete(_ sender: Any?) {
    if completionContext.isPanelVisible {
      cancelCompletion()
    } else {
      bridge.completion.startCompletion(afterDelay: 0)
    }
  }

  override func cancelOperation(_ sender: Any?) {
    if completionContext.isPanelVisible {
      cancelCompletion()
    }
  }

  override var representedObject: Any? {
    didSet {
      resetEditor()
    }
  }
}

// MARK: - Exposed Methods

extension EditorViewController {
  func clearEditor() {
    bridge.core.clearEditor()
    updateTextFinderMode(.hidden, searchTerm: "")
  }

  func resetEditor() {
    guard hasFinishedLoading, let text = document?.stringValue else {
      return
    }

    // Toggling isHidden because line numbers are initially rendered as only "1",
    // it gets fixed after resetting the text, but takes time especially for huge documents.
    webView.isHidden = true

    bridge.core.resetEditor(text: text) { _ in
      self.webView.isHidden = false
      self.bridge.textChecker.update(options: TextCheckerOptions(
        spellcheck: true,
        autocorrect: true
      ))

      Grammarly.shared.update(bridge: self.bridge.grammarly, wasReset: true)
    }
  }

  func markEditorDirty(_ isDirty: Bool) {
    bridge.core.markEditorDirty(isDirty: isDirty)
  }
}
