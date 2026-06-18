//
//  QuickLookViewController.swift
//  QuickLookMac
//
//  Created by cyan on 12/20/22.
//

import AppKit
import QuickLookUI
import WebKit
import MarkEditCore

final class QuickLookViewController: NSViewController {
  var guidanceView: NSView?
  var mouseDownMonitor: Any?
  var mouseDragMonitor: Any?
  var mouseUpMonitor: Any?
  var isDraggingScroller = false

  weak var defaultOpenTarget: AnyObject?
  var defaultOpenAction: Selector?

  private var previewDirectoryURL: URL?
  private var appearanceObservation: NSKeyValueObservation?
  private weak var observedResizeWindow: NSWindow?

  lazy var webView: WKWebView = {
    let config: WKWebViewConfiguration = .preferredConfig()
    config.enablePerformanceFlags()
    config.disableAllRichFeatures()

    // [macOS 26.6] WebKit regression that blocks url scheme tasks
    config.setObjectValue(
      ["\(EditorImageLoader.scheme)://*/*"] as NSArray,
      forSelector: "_setCORSDisablingPatterns:"
    )

    // E.g., markedit-preview.js
    let controller = WKUserContentController()
    config.userContentController = controller
    userScripts.forEach {
      controller.addUserScript($0)
    }

    // E.g., image-loader://photo.png
    config.setURLSchemeHandler(
      EditorImageLoader { [weak self] in
        self?.previewDirectoryURL
      },
      forURLScheme: EditorImageLoader.scheme
    )

    let webView = QuickLookWebView(frame: .zero, configuration: config)
    webView.navigationDelegate = self
    return webView
  }()

  override var nibName: NSNib.Name? {
    NSNib.Name("Main")
  }

  deinit {
    NotificationCenter.default.removeObserver(self)

    MainActor.assumeIsolated {
      if let mouseDownMonitor {
        NSEvent.removeMonitor(mouseDownMonitor)
        self.mouseDownMonitor = nil
      }

      if let mouseDragMonitor {
        NSEvent.removeMonitor(mouseDragMonitor)
        self.mouseDragMonitor = nil
      }
    }

    if let mouseUpMonitor {
      NSEvent.removeMonitor(mouseUpMonitor)
      self.mouseUpMonitor = nil
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    if let size = QuickLookWindowSize.savedValue {
      preferredContentSize = size
    }

    view.wantsLayer = true
    view.addSubview(webView)

    // [macOS 14] It's not clipped by default
    view.layer?.masksToBounds = true
    view.layer?.cornerRadius = 6

    addEventMonitorsForDragging()
    updateAppearance()

    appearanceObservation = NSApp.observe(\.effectiveAppearance) { [weak self] _, _ in
      guard let self else {
        return
      }

      Task { @MainActor in
        self.updateAppearance()
      }
    }
  }

  override func viewDidAppear() {
    super.viewDidAppear()
    observeWindowResize()
  }

  override func viewDidLayout() {
    super.viewDidLayout()
    webView.frame = view.bounds
    guidanceView?.frame = view.bounds

    if view.window != nil {
      disableDefaultOpen()
    }
  }
}

// MARK: - QLPreviewingController

extension QuickLookViewController: QLPreviewingController {
  func preparePreviewOfFile(at url: URL) async throws {
    guard EditorIndexHtml.sharedFileExists else {
      return showSetUpGuidance()
    }

    let fileURL = textFileURL(of: url)
    previewDirectoryURL = fileURL.deletingLastPathComponent()

    let config = EditorConfig.quicklookConfig(
      fileData: try Data(contentsOf: fileURL)
    )

    let index = [EditorIndexHtml.fromSharedContainer(config: config)]
    let html = (index + userStyles).joined(separator: "\n\n")
    webView.loadHTMLString(html, baseURL: URL(string: "http://localhost/"))
  }
}

// MARK: - WKNavigationDelegate

extension QuickLookViewController: WKNavigationDelegate {
  func webView(
    _ webView: WKWebView,
    decidePolicyFor navigationAction: WKNavigationAction,
    decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void
  ) {
    decisionHandler(navigationAction.navigationType == .linkActivated ? .cancel : .allow)
  }
}

// MARK: - Private

private extension QuickLookViewController {
  func observeWindowResize() {
    guard let window = view.window, window.level == .floating, window !== observedResizeWindow else {
      return
    }

    if let observedResizeWindow {
      NotificationCenter.default.removeObserver(
        self,
        name: NSWindow.didEndLiveResizeNotification,
        object: observedResizeWindow
      )
    }

    observedResizeWindow = window
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(windowDidResize(_:)),
      name: NSWindow.didEndLiveResizeNotification,
      object: window
    )
  }

  @objc func windowDidResize(_ notification: Notification) {
    guard let window = notification.object as? NSWindow, window.level == .floating else {
      return
    }

    QuickLookWindowSize.savedValue = view.bounds.size
  }
}
