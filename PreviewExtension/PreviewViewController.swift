//
//  PreviewViewController.swift
//  PreviewExtension
//
//  Created by cyan on 12/20/22.
//

import Cocoa
import QuickLookUI
import WebKit
import MarkEditCore

final class PreviewViewController: NSViewController, QLPreviewingController {
  private var appearanceObservation: NSKeyValueObservation?
  private let webView: WKWebView = {
    let config = WKWebViewConfiguration()
    if config.responds(to: sel_getUid("_drawsBackground")) {
      config.setValue(false, forKey: "drawsBackground")
    }

    return WKWebView(frame: .zero, configuration: config)
  }()

  override var nibName: NSNib.Name? {
    NSNib.Name("Main")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(webView)

    appearanceObservation = NSApp.observe(\.effectiveAppearance) { [weak self] _, _ in
      self?.updateEditorTheme()
    }
  }

  override func viewDidLayout() {
    super.viewDidLayout()
    webView.frame = view.bounds
  }

  func preparePreviewOfFile(at url: URL) async throws {
    let data = try Data(contentsOf: textFileURL(of: url))
    let config = EditorConfig(
      text: data.toString() ?? "",
      theme: effectiveTheme,
      fontFamily: "ui-monospace",
      fontSize: 12,
      showLineNumbers: false,
      showActiveLineIndicator: false,
      invisiblesBehavior: .always,
      typewriterMode: false,
      focusMode: false,
      lineWrapping: true,
      lineHeight: 1.4,
      suggestWhileTyping: false,
      defaultLineBreak: nil,
      tabKeyBehavior: nil,
      indentUnit: nil,
      localizable: nil
    )

    webView.loadHTMLString(config.toHtml, baseURL: nil)
  }
}

// MARK: - Private

private extension PreviewViewController {
  var effectiveTheme: String {
    NSApp.effectiveAppearance.isDarkMode ? "github-dark" : "github-light"
  }

  func updateEditorTheme() {
    // To keep the app size smaller, we don't have bridge here,
    // construct script literals directly.
    webView.evaluateJavaScript("setTheme(`\(effectiveTheme)`)")
  }

  func textFileURL(of url: URL) -> URL {
    // The text.* file inside a text bundle
    if url.pathExtension.lowercased() == "textbundle", let contents = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) {
      return contents.first {
        let filename = $0.lastPathComponent.lowercased()
        return filename.hasPrefix("text.") && filename != "text.html"
      } ?? url
    }

    // Markdown file
    return url
  }
}

private extension NSAppearance {
  var isDarkMode: Bool {
    switch name {
    case .darkAqua, .vibrantDark, .accessibilityHighContrastDarkAqua, .accessibilityHighContrastVibrantDark:
      return true
    default:
      return false
    }
  }
}
