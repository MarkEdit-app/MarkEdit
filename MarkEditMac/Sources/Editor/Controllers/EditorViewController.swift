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
    controller.add(handler, name: "bridge")

    let config: WKWebViewConfiguration = .newConfig()
    config.processPool = EditorReusePool.shared.processPool
    config.userContentController = controller

    let webView = EditorWebView(frame: .zero, configuration: config)
    webView.uiDelegate = self
    webView.menuDelegate = self

    let html = [
      AppPreferences.editorConfig.toHtml,
      EditorStyleSheet.shared.contents,
    ].joined(separator: "\n\n")

    // Non-nil baseURL is required by web services like Grammarly
    let baseURL = URL(string: "http://localhost")
    webView.loadHTMLString(html, baseURL: baseURL)

    return webView
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

    // Hide the window to mitigate the WKWebView loading latency,
    // reset it after finished rendering the text.
    //
    // It takes a bit longer to show the window but also makes the experience better.
    if !hasFinishedLoading {
      setWindowHidden(true)
    }
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

    webView.isHidden = true
    bridge.core.resetEditor(text: text) { _ in
      self.setWindowHidden(false)
      self.bridge.textChecker.update(options: TextCheckerOptions(
        spellcheck: true,
        autocorrect: true
      ))

      Grammarly.shared.update(bridge: self.bridge.grammarly)

      // Dirty trick, show the content later to wait CodeMirror finishes its initial layout,
      // the line number height is not initially correct because of the window animation.
      DispatchQueue.afterDelay(seconds: 0.05) {
        self.webView.isHidden = false
      }
    }
  }

  func markEditorDirty(_ isDirty: Bool) {
    bridge.core.markEditorDirty(isDirty: isDirty)
  }
}
