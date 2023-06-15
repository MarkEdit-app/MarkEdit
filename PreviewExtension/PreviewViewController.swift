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

  private lazy var webView: WKWebView = {
    let config = WKWebViewConfiguration()
    if config.responds(to: sel_getUid("_drawsBackground")) {
      config.setValue(false, forKey: "drawsBackground")
    }

    let webView = WKWebView(frame: .zero, configuration: config)
    webView.layer?.masksToBounds = true
    webView.layer?.cornerRadius = 6 // [macOS 14] It's not clipped by default
    return webView
  }()

  override var nibName: NSNib.Name? {
    NSNib.Name("Main")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(webView)

    addEventMonitorsForDragging()
    updateBackgroundColor()

    appearanceObservation = NSApp.observe(\.effectiveAppearance) { [weak self] _, _ in
      self?.updateBackgroundColor()
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
  var isDarkMode: Bool {
    switch NSApp.effectiveAppearance.name {
    case .darkAqua, .vibrantDark, .accessibilityHighContrastDarkAqua, .accessibilityHighContrastVibrantDark:
      return true
    default:
      return false
    }
  }

  var isRightToLeft: Bool {
    view.userInterfaceLayoutDirection == .rightToLeft
  }

  var effectiveTheme: String {
    isDarkMode ? "github-dark" : "github-light"
  }

  func updateBackgroundColor() {
    // To hide the transparent background of the scrolling overflow
    view.wantsLayer = true
    view.layer?.backgroundColor = (isDarkMode ? NSColor(red: 13.0 / 255, green: 17.0 / 255, blue: 22.0 / 255, alpha: 1) : NSColor.white).cgColor
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

// MARK: - Dragging
//
// #194 Dragging behavior in preview extension is wacky,
// override the event handling and make a homemade scrolling strategy.
private extension PreviewViewController {
  var overrideDragging: Bool {
    // Don't handle floating windows,
    // which is typically a larger window triggered by pressing spacebar in Finder.
    NSApp.windows.allSatisfy { $0.level == .normal }
  }

  func addEventMonitorsForDragging() {
    NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
      guard let self, self.overrideDragging else {
        return event
      }

      return self.startDragging(event: event) ? nil : event
    }

    NSEvent.addLocalMonitorForEvents(matching: .leftMouseDragged) { [weak self] event in
      guard let self, self.overrideDragging else {
        return event
      }

      self.updateDragging(event: event)
      return nil
    }
  }

  func startDragging(event: NSEvent) -> Bool {
    let location = webView.convert(event.locationInWindow, from: nil)
    let scrollerWidth = NSScroller.scrollerWidth(for: .regular, scrollerStyle: .overlay)

    // Dragging is started only if the click is inside the scroller
    if isRightToLeft ? location.x < scrollerWidth : location.x > view.frame.width - scrollerWidth {
      webView.evaluateJavaScript("startDragging(\(location.y))")
      return true
    } else {
      webView.evaluateJavaScript("cancelDragging()")
      return false
    }
  }

  func updateDragging(event: NSEvent) {
    let location = webView.convert(event.locationInWindow, from: nil)
    webView.evaluateJavaScript("updateDragging(\(location.y))")
  }
}
