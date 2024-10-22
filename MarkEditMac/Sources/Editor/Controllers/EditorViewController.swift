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
import Statistics
import TextCompletion

final class EditorViewController: NSViewController {
  var hasFinishedLoading = false
  var hasUnfinishedAnimations = false
  var hasBeenEdited = false
  var mouseExitedWindow = false
  var bottomPanelHeight: Double = 0
  var webBackgroundColor: NSColor?
  var localEventMonitor: Any?
  var writingToolsObservation: NSKeyValueObservation?
  var safeAreaObservation: NSKeyValueObservation?
  var userDefinedMenuItems = [EditorMenuItem]()

  weak var presentedMenu: NSMenu?
  weak var presentedPopover: NSPopover? {
    willSet {
      // Close the existing popover to ensure that only one is presented
      presentedPopover?.close()
    }
  }

  var editorText: String? {
    get async {
      guard hasFinishedLoading else {
        return nil
      }

      return try? await bridge.core.getEditorText()
    }
  }

  var tableOfContents: [HeadingInfo]? {
    get async {
      guard hasFinishedLoading else {
        return nil
      }

      return try? await bridge.toc.getTableOfContents()
    }
  }

  /// Whether the content is editable, the user can toggle the read-only state at any time.
  var isReadOnlyMode: Bool {
    get {
      document?.isReadOnlyMode ?? false
    }
    set {
      document?.isReadOnlyMode = newValue
    }
  }

  /// Whether the revisions of the document are being reviewed, i.e., version browsing mode.
  var isRevisionMode: Bool {
    document?.isInViewingMode ?? false
  }

  lazy var bridge = WebModuleBridge(
    webView: webView
  )

  var document: EditorDocument? {
    representedObject as? EditorDocument
  }

  var isFindPanelFirstResponder: Bool {
    guard findPanel.mode != .hidden else {
      return false
    }

    return findPanel.isFirstResponder || replacePanel.isFirstResponder
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

  private(set) lazy var loadingIndicator: NSView = {
    class View: NSImageView {
      override func hitTest(_ point: NSPoint) -> NSView? { nil }
    }

    let view = View()
    view.image = NSImage(named: "AppIcon")

    Logger.assert(view.image != nil, "Missing AppIcon from the main bundle")
    return view
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
      EditorModuleUI(delegate: self),
    ])

    let handler = EditorMessageHandler(modules: modules)
    let controller = WKUserContentController()
    controller.addScriptMessageHandler(handler, contentWorld: .page, name: "bridge")

    let scripts = [
      AppCustomization.editorScript.fileContents,
    ] + AppCustomization.scriptsDirectory.directoryContents

    scripts.forEach {
      controller.addUserScript(WKUserScript(
        source: $0,
        injectionTime: .atDocumentEnd,
        forMainFrameOnly: false
      ))
    }

    let config: WKWebViewConfiguration = .newConfig(disableCors: AppRuntimeConfig.disableCorsRestrictions)
    config.applicationNameForUserAgent = "\(ProcessInfo.processInfo.userAgent) \(Bundle.main.userAgent)"
    config.setURLSchemeHandler(EditorChunkLoader(), forURLScheme: EditorChunkLoader.scheme)
    config.allowsInlinePredictions = NSSpellChecker.InlineCompletion.webKitEnabled

    // [macOS 15] Enable complete mode for WritingTools, need this because its public API is not ready
    if #available(macOS 15.1, *), let writingToolsBehavior = AppRuntimeConfig.writingToolsBehavior {
      if config.responds(to: sel_getUid("setWritingToolsBehavior:")) {
        config.setValue(writingToolsBehavior, forKey: "writingToolsBehavior")
      } else {
        Logger.assertFail("Missing setWritingToolsBehavior: method in WKWebViewConfiguration")
      }
    }

    config.processPool = EditorReusePool.shared.processPool
    config.userContentController = controller

    let webView = EditorWebView(frame: .zero, configuration: config)
    webView.isInspectable = true
    webView.allowsMagnification = true
    webView.uiDelegate = self
    webView.actionDelegate = self

    let theme = AppTheme.current.editorTheme
    DispatchQueue.global(qos: .userInitiated).async {
      let html = [
        AppPreferences.editorConfig(theme: theme).toHtml,
        AppCustomization.editorStyle.fileContents,
        AppCustomization.stylesDirectory.directoryContents.joined(separator: "\n"),
      ].joined(separator: "\n\n")

      DispatchQueue.main.async {
        // Non-nil baseURL is required by scenarios like opening local files
        webView.loadHTMLString(html, baseURL: EditorWebView.baseURL)
      }
    }

    // [macOS 15] Detect WritingTools visibility to work around issues
    if #available(macOS 15.1, *) {
      writingToolsObservation = webView.observe(\.isWritingToolsActive) { [weak self] _, _ in
        guard let self else {
          return
        }

        self.updateWritingTools(isActive: self.webView.isWritingToolsActive)
      }
    }

    return webView
  }()

  private(set) lazy var spellChecker = {
    NSSpellChecker()
  }()

  private(set) lazy var completionContext = {
    TextCompletionContext(
      localize: TextCompletionLocalizable(selectedHint: Localized.General.selected)
    ) { [weak self] in
      guard let self else {
        return
      }

      Task { @MainActor in
        self.commitCompletion()
      }
    }
  }()

  deinit {
    if let monitor = localEventMonitor {
      NSEvent.removeMonitor(monitor)
      localEventMonitor = nil
    }
  }

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
    layoutLoadingIndicator()
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
    if isFindPanelFirstResponder {
      updateTextFinderMode(.hidden)
    }

    if webView.isFirstResponder {
      removeFloatingUIElements()
    }

    removePresentedPopovers(contentClass: StatisticsController.self)
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
    updateTextFinderMode(.hidden, searchTerm: "")

    // The delay is in theory not necessary,
    // because autosave happens before closing the window.
    //
    // Just in case someone introduces race conditions.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      self.bridge.core.clearEditor()
    }
  }

  func resetEditor() {
    guard hasFinishedLoading else {
      return
    }

    bridge.core.resetEditor(text: document?.stringValue ?? "", revision: document?.latestRevision, revisionMode: isRevisionMode) { _ in
      self.webView.magnification = 1.0
      self.bridge.textChecker.update(options: TextCheckerOptions(
        spellcheck: true,
        autocorrect: true
      ))
    }

    // Disable unnecessary UI elements for revision mode
    if let identifier = view.window?.toolbar?.identifier, !identifier.isEmpty {
      view.window?.toolbar?.allowsUserCustomization = !isRevisionMode
    }

    hasBeenEdited = false
    findPanel.searchField.isHidden = isRevisionMode
    setShowSelectionStatus(enabled: AppPreferences.Editor.showSelectionStatus)
  }

  func handleFileURLChange() {
    guard hasBeenEdited else {
      return
    }

    bridge.history.markContentClean()
  }

  func ensureWritingToolsSelectionRect() {
    bridge.writingTools.ensureSelectionRect()
  }
}
