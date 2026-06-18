//
//  PreviewViewController.swift
//  PreviewExtension
//
//  Created by cyan on 12/20/22.
//

import AppKit
import QuickLookUI
import WebKit
import MarkEditCore

final class PreviewViewController: NSViewController {
  var mouseDownMonitor: Any?
  var mouseDragMonitor: Any?

  weak var defaultOpenTarget: AnyObject?
  var defaultOpenAction: Selector?

  private var previewDirectoryURL: URL?
  private var appearanceObservation: NSKeyValueObservation?

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

    let webView = PreviewViewWebView(frame: .zero, configuration: config)
    webView.navigationDelegate = self
    return webView
  }()

  override var nibName: NSNib.Name? {
    NSNib.Name("Main")
  }

  deinit {
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
  }

  override func viewDidLoad() {
    super.viewDidLoad()
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

  override func viewDidLayout() {
    super.viewDidLayout()
    webView.frame = view.bounds

    if view.window != nil {
      disableDefaultOpen()
    }
  }
}

// MARK: - QLPreviewingController

extension PreviewViewController: QLPreviewingController {
  func preparePreviewOfFile(at url: URL) async throws {
    let fileURL = textFileURL(of: url)
    previewDirectoryURL = fileURL.deletingLastPathComponent()

    let config = EditorConfig.previewConfig(
      fileData: try Data(contentsOf: fileURL)
    )

    let html = ([config.toHtml] + userStyles).joined(separator: "\n\n")
    webView.loadHTMLString(html, baseURL: URL(string: "http://localhost/"))
  }
}

// MARK: - WKNavigationDelegate

extension PreviewViewController: WKNavigationDelegate {
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
    webView.window?.makeFirstResponder(webView)
  }

  func webView(
    _ webView: WKWebView,
    decidePolicyFor navigationAction: WKNavigationAction,
    decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void
  ) {
    decisionHandler(navigationAction.navigationType == .linkActivated ? .cancel : .allow)
  }
}
