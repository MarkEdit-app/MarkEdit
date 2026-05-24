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
  var defaultOpenTarget: Any?
  var defaultOpenAction: Selector?

  private var previewDirectoryURL: URL?
  private var appearanceObservation: NSKeyValueObservation?

  lazy var webView: WKWebView = {
    class Configuration: WKWebViewConfiguration {
      @objc func _drawsBackground() -> Bool { false }
    }

    let config = Configuration()
    config.enablePerformanceFlags()
    config.disableAllRichFeatures()

    // E.g., markedit-preview.js
    let controller = WKUserContentController()
    config.userContentController = controller
    userScripts?.forEach {
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
    if let mouseDownMonitor {
      NSEvent.removeMonitor(mouseDownMonitor)
      self.mouseDownMonitor = nil
    }

    if let mouseDragMonitor {
      NSEvent.removeMonitor(mouseDragMonitor)
      self.mouseDragMonitor = nil
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
    updateBackgroundColor()

    appearanceObservation = NSApp.observe(\.effectiveAppearance) { [weak self] _, _ in
      guard let self else {
        return
      }

      Task { @MainActor in
        self.updateBackgroundColor()
        self.updateEditorTheme()
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
      fileData: try Data(contentsOf: fileURL),
      theme: effectiveTheme
    )

    let html = config.toHtml
    webView.loadHTMLString(html, baseURL: URL(string: "http://localhost/"))
  }
}

// MARK: - WKNavigationDelegate

extension PreviewViewController: WKNavigationDelegate {
  func webView(
    _ webView: WKWebView,
    decidePolicyFor navigationAction: WKNavigationAction,
    decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
  ) {
    decisionHandler(navigationAction.navigationType == .linkActivated ? .cancel : .allow)
  }
}
