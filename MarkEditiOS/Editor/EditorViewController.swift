//
//  EditorViewController.swift
//  MarkEditiOS
//
//  UIViewController that hosts the CodeMirror-based WKWebView editor.
//  Mirrors the role of EditorViewController in MarkEditMac but uses UIKit instead of AppKit.
//

import UIKit
import WebKit
import MarkEditCore
import MarkEditKit

@MainActor
final class EditorViewController: UIViewController {

  // MARK: - State

  private let document: MarkEditDocument
  private var hasFinishedLoading = false
  private var hasBeenEdited = false
  private var keyboardAccessoryView: EditorToolbar?

  // MARK: - Editor Bridge

  private(set) lazy var bridge = WebModuleBridge(webView: webView)

  // MARK: - Web View

  private(set) lazy var webView: WKWebView = {
    let modules = NativeModules(modules: [
      EditorModuleCore(delegate: self),
      EditorModuleTokenizer(),
      EditorModuleAPI(delegate: self),
    ])

    let handler = EditorMessageHandler(modules: modules)
    let contentController = WKUserContentController()
    contentController.addScriptMessageHandler(handler, contentWorld: .page, name: "bridge")

    let config = WKWebViewConfiguration.newConfig()
    config.userContentController = contentController
    config.applicationNameForUserAgent = "MarkEditiOS/1.0"

    let chunkLoader = EditorChunkLoader()
    config.setURLSchemeHandler(chunkLoader, forURLScheme: EditorChunkLoader.scheme)

    let wv = WKWebView(frame: .zero, configuration: config)
    wv.isInspectable = true
    wv.uiDelegate = self
    wv.scrollView.contentInsetAdjustmentBehavior = .never
    wv.translatesAutoresizingMaskIntoConstraints = false

    // Disable rubber-band scrolling — the CodeMirror editor manages its own scroll
    wv.scrollView.bounces = false

    // Load the initial HTML synchronously so the editor is ready when the view appears
    let html = makeEditorHTML()
    wv.loadHTMLString(html, baseURL: URL(string: "http://localhost/"))

    return wv
  }()

  // MARK: - Init

  init(document: MarkEditDocument) {
    self.document = document
    super.init(nibName: nil, bundle: nil)
    title = document.displayName
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - View Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    setupWebView()
    setupNavigationBar()
    setupKeyboardObservers()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    // Save whenever the editor leaves the screen (back button, swipe-dismiss, etc.)
    if isBeingDismissed || isMovingFromParent {
      saveDocumentNow()
    }
  }

  // MARK: - Private Layout

  private func setupWebView() {
    view.addSubview(webView)
    NSLayoutConstraint.activate([
      webView.topAnchor.constraint(equalTo: view.topAnchor),
      webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  private func setupNavigationBar() {
    let settingsButton = UIBarButtonItem(
      image: UIImage(systemName: "gearshape"),
      style: .plain,
      target: self,
      action: #selector(showSettings)
    )

    let shareButton = UIBarButtonItem(
      image: UIImage(systemName: "square.and.arrow.up"),
      style: .plain,
      target: self,
      action: #selector(shareDocument)
    )

    navigationItem.rightBarButtonItems = [shareButton, settingsButton]

    // Left side: back button that saves and returns to document browser
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      title: "Documents",
      style: .plain,
      target: self,
      action: #selector(closeEditor)
    )
  }

  // MARK: - Actions

  @objc private func closeEditor() {
    saveDocumentNow()
    dismiss(animated: true)
  }

  @objc private func showSettings() {
    let settingsVC = SettingsViewController()
    settingsVC.onDismiss = { [weak self] in
      self?.applySettingsToEditor()
    }
    let nav = UINavigationController(rootViewController: settingsVC)
    nav.modalPresentationStyle = .formSheet
    present(nav, animated: true)
  }

  @objc private func shareDocument() {
    guard let fileURL = document.fileURL as URL? else { return }

    // Ensure file is current before sharing
    saveDocumentNow()

    let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)

    // iPad needs a popover anchor
    if let barButton = navigationItem.rightBarButtonItems?.first {
      activityVC.popoverPresentationController?.barButtonItem = barButton
    }

    present(activityVC, animated: true)
  }

  // MARK: - Keyboard Toolbar Accessory

  private func setupKeyboardObservers() {
    let toolbar = EditorToolbar { [weak self] tag in
      self?.handleToolbarAction(tag)
    }
    keyboardAccessoryView = toolbar

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillShow(_:)),
      name: UIResponder.keyboardWillShowNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillHide(_:)),
      name: UIResponder.keyboardWillHideNotification,
      object: nil
    )
  }

  @objc private func keyboardWillShow(_ notification: Notification) {
    guard let toolbar = keyboardAccessoryView,
          let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
          let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
    else { return }

    if toolbar.superview == nil {
      toolbar.frame = CGRect(
        x: 0,
        y: view.bounds.height - keyboardFrame.height - toolbar.intrinsicContentSize.height,
        width: view.bounds.width,
        height: toolbar.intrinsicContentSize.height
      )
      toolbar.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
      view.addSubview(toolbar)
    }

    UIView.animate(withDuration: duration) {
      let toolbarHeight = toolbar.intrinsicContentSize.height
      toolbar.frame.origin.y = self.view.bounds.height - keyboardFrame.height - toolbarHeight
    }

    // Shrink web view bottom so content isn't hidden behind keyboard + toolbar
    let toolbarHeight = toolbar.intrinsicContentSize.height
    let inset = keyboardFrame.height + toolbarHeight
    webView.scrollView.contentInset.bottom = inset
    webView.scrollView.verticalScrollIndicatorInsets.bottom = inset
  }

  @objc private func keyboardWillHide(_ notification: Notification) {
    guard let toolbar = keyboardAccessoryView,
          let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
    else { return }

    UIView.animate(withDuration: duration) {
      toolbar.frame.origin.y = self.view.bounds.height
    } completion: { _ in
      toolbar.removeFromSuperview()
    }

    webView.scrollView.contentInset.bottom = 0
    webView.scrollView.verticalScrollIndicatorInsets.bottom = 0
  }

  private func handleToolbarAction(_ tag: EditorToolbar.Tag) {
    switch tag {
    case .bold:    bridge.format.toggleBold()
    case .italic:  bridge.format.toggleItalic()
    case .code:    bridge.format.toggleInlineCode()
    case .link:    presentLinkInsertion()
    case .heading: bridge.format.toggleHeading(level: 1)
    case .done:    view.endEditing(true)
    }
  }

  private func presentLinkInsertion() {
    let alert = UIAlertController(title: "Insert Link", message: nil, preferredStyle: .alert)
    alert.addTextField { tf in
      tf.placeholder = "Display text"
      tf.clearButtonMode = .whileEditing
    }
    alert.addTextField { tf in
      tf.placeholder = "https://"
      tf.keyboardType = .URL
      tf.autocapitalizationType = .none
      tf.clearButtonMode = .whileEditing
    }
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    alert.addAction(UIAlertAction(title: "Insert", style: .default) { [weak self, weak alert] _ in
      let title = alert?.textFields?[0].text ?? ""
      let url   = alert?.textFields?[1].text ?? ""
      self?.bridge.format.insertHyperLink(title: title, url: url, prefix: nil)
    })
    present(alert, animated: true)
  }

  // MARK: - Settings Application

  func applySettingsToEditor() {
    guard hasFinishedLoading else { return }
    bridge.config.setTheme(name: AppPreferences.Editor.theme)
    bridge.config.setFontSize(fontSize: AppPreferences.Editor.fontSize)
    bridge.config.setLineWrapping(enabled: AppPreferences.Editor.lineWrapping)
    bridge.config.setShowLineNumbers(enabled: AppPreferences.Editor.showLineNumbers)
  }

  // MARK: - Document Save

  func saveDocumentNow() {
    Task { @MainActor in
      if hasFinishedLoading, let text = try? await bridge.core.getEditorText() {
        document.stringValue = text
      }
      document.save(to: document.fileURL, for: .forOverwriting) { _ in }
    }
  }

  // MARK: - HTML Generation

  private func makeEditorHTML() -> String {
    let config = EditorConfig(
      text: "",
      theme: AppPreferences.Editor.theme,
      fontFace: WebFontFace(family: "ui-monospace, monospace", weight: nil, style: nil),
      fontSize: AppPreferences.Editor.fontSize,
      showLineNumbers: AppPreferences.Editor.showLineNumbers,
      showActiveLineIndicator: true,
      invisiblesBehavior: .never,
      readOnlyMode: false,
      typewriterMode: false,
      focusMode: false,
      lineWrapping: AppPreferences.Editor.lineWrapping,
      lineHeight: 1.6,
      suggestWhileTyping: false,
      standardDirectories: URL.standardDirectories,
      defaultLineBreak: nil,
      tabKeyBehavior: nil,
      indentUnit: nil,
      localizable: nil,
      autoCharacterPairs: true,
      indentBehavior: .paragraph,
      headerFontSizeDiffs: nil,
      visibleWhitespaceCharacter: nil,
      visibleLineBreakCharacter: nil,
      searchNormalizers: nil
    )
    return config.toHtml
  }
}

// MARK: - WKUIDelegate

extension EditorViewController: WKUIDelegate {
  func webView(
    _ webView: WKWebView,
    createWebViewWith configuration: WKWebViewConfiguration,
    for navigationAction: WKNavigationAction,
    windowFeatures: WKWindowFeatures
  ) -> WKWebView? {
    // Open links in Safari instead of in a new web view
    if let url = navigationAction.request.url, url.scheme == "https" || url.scheme == "http" {
      UIApplication.shared.open(url)
    }
    return nil
  }
}

// MARK: - EditorModuleCoreDelegate

extension EditorViewController: EditorModuleCoreDelegate {
  func editorCoreWindowDidLoad(_ sender: EditorModuleCore) {
    hasFinishedLoading = true
    // Load the document content into the editor
    bridge.core.resetEditor(text: document.stringValue) { [weak self] _ in
      guard let self else { return }
      self.applySettingsToEditor()
    }
  }

  func editorCoreEditorDidBecomeIdle(_ sender: EditorModuleCore) {
    // Autosave when the editor becomes idle after editing
    if hasBeenEdited {
      saveDocumentNow()
    }
  }

  func editorCoreBackgroundColorDidChange(_ sender: EditorModuleCore, color: UInt32, alpha: Double) {
    // Update the web view background to match the editor theme
    let red   = CGFloat((color >> 16) & 0xFF) / 255.0
    let green = CGFloat((color >> 8)  & 0xFF) / 255.0
    let blue  = CGFloat( color        & 0xFF) / 255.0
    let uiColor = UIColor(red: red, green: green, blue: blue, alpha: CGFloat(alpha))
    webView.backgroundColor = uiColor
    view.backgroundColor = uiColor
  }

  func editorCoreViewportScaleDidChange(_ sender: EditorModuleCore) {}

  func editorCoreViewDidUpdate(
    _ sender: EditorModuleCore,
    contentEdited: Bool,
    compositionEnded: Bool,
    isDirty: Bool,
    selectedLineColumn: LineColumnInfo
  ) {
    if contentEdited {
      hasBeenEdited = true
      document.updateChangeCount(.done)
    }
  }

  func editorCoreContentHeightDidChange(_ sender: EditorModuleCore, bottomPanelHeight: Double) {}

  func editorCoreContentOffsetDidChange(_ sender: EditorModuleCore) {}

  func editorCoreCompositionEnded(_ sender: EditorModuleCore, selectedLineColumn: LineColumnInfo) {}

  func editorCoreLinkClicked(_ sender: EditorModuleCore, link: String) {
    let url: URL?
    if let urlWithScheme = URL(string: link), urlWithScheme.scheme?.isEmpty == false {
      url = urlWithScheme
    } else {
      // Relative link — resolve against the document's folder
      url = document.fileURL.deletingLastPathComponent().appendingPathComponent(link)
    }

    if let url {
      UIApplication.shared.open(url)
    }
  }

  func editorCoreLightWarning(_ sender: EditorModuleCore) {
    // Provide haptic feedback as the iOS equivalent of NSSound.beep()
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(.warning)
  }
}

// MARK: - EditorModuleAPIDelegate

extension EditorViewController: EditorModuleAPIDelegate {
  func editorAPIOpenFile(_ sender: EditorModuleAPI, fileURL: URL) -> Bool {
    UIApplication.shared.open(fileURL)
    return true
  }

  func editorAPIGetFileURL(_ sender: EditorModuleAPI, path: String?) -> URL? {
    guard let path else { return document.fileURL }
    return URL(filePath: path)
  }

  func editorAPI(_ sender: EditorModuleAPI, addMainMenuItems items: [(String, WebMenuItem)]) {
    // No main-menu equivalent on iOS — no-op
  }

  func editorAPI(_ sender: EditorModuleAPI, showContextMenu items: [WebMenuItem], location: WebPoint) {
    // Build a UIAlertController action sheet for user-defined context-menu items
    guard !items.isEmpty else { return }

    let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    for item in items {
      guard let title = item.title, !item.separator else { continue }
      let actionID = item.actionID
      sheet.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
        guard let self, let actionID else { return }
        self.bridge.api.handleContextMenuAction(id: actionID)
      })
    }
    sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

    // iPad popover anchor
    sheet.popoverPresentationController?.sourceView = webView
    sheet.popoverPresentationController?.sourceRect = CGRect(
      x: location.x, y: location.y, width: 1, height: 1
    )
    present(sheet, animated: true)
  }

  func editorAPI(
    _ sender: EditorModuleAPI,
    alertWith title: String?,
    message: String?,
    buttons: [String]?
  ) async -> Int {
    await withCheckedContinuation { continuation in
      let alert = UIAlertController(
        title: title,
        message: message,
        preferredStyle: .alert
      )

      let buttonTitles = buttons?.isEmpty == false ? buttons! : ["OK"]
      for (index, buttonTitle) in buttonTitles.enumerated() {
        alert.addAction(UIAlertAction(title: buttonTitle, style: .default) { _ in
          continuation.resume(returning: index)
        })
      }

      if alert.actions.isEmpty {
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
          continuation.resume(returning: 0)
        })
      }

      present(alert, animated: true)
    }
  }

  func editorAPI(
    _ sender: EditorModuleAPI,
    showTextBox title: String?,
    placeholder: String?,
    defaultValue: String?
  ) async -> String? {
    await withCheckedContinuation { continuation in
      let alert = UIAlertController(
        title: title,
        message: nil,
        preferredStyle: .alert
      )
      alert.addTextField { tf in
        tf.placeholder = placeholder
        tf.text = defaultValue
      }
      alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
        continuation.resume(returning: nil)
      })
      alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
        continuation.resume(returning: alert.textFields?.first?.text)
      })
      present(alert, animated: true)
    }
  }

  func editorAPI(_ sender: EditorModuleAPI, showSavePanel data: Data, fileName: String?) async -> Bool {
    // Write data to a temp file then present share sheet
    let name = fileName ?? "export"
    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(name)
    do {
      try data.write(to: tempURL, options: .atomic)
    } catch {
      return false
    }

    return await withCheckedContinuation { continuation in
      let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
      activityVC.completionWithItemsHandler = { _, completed, _, _ in
        continuation.resume(returning: completed)
      }
      if let barButton = navigationItem.rightBarButtonItems?.first {
        activityVC.popoverPresentationController?.barButtonItem = barButton
      }
      present(activityVC, animated: true)
    }
  }

  func editorAPI(_ sender: EditorModuleAPI, runService name: String, input: String?) async -> Bool {
    // No NSServices equivalent on iOS
    return false
  }
}

