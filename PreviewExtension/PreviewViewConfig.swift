//
//  PreviewViewConfig.swift
//  PreviewExtension
//
//  Created by cyan on 5/26/26.
//

import Foundation
import WebKit
import MarkEditCore

extension PreviewViewController {
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

  var userScripts: [WKUserScript]? {
    guard let scriptsURL = URL.sharedContainerURL?.appending(
      path: "Shared/scripts",
      directoryHint: .isDirectory
    ) else {
      return nil
    }

    return scriptsURL.sortedFiles(types: ["js"]).compactMap {
      guard let source = try? String(contentsOf: $0, encoding: .utf8) else {
        return nil
      }

      return WKUserScript(
        source: source,
        injectionTime: .atDocumentEnd,
        forMainFrameOnly: false
      )
    }
  }
}

extension WKWebViewConfiguration {
  // Disables all rich JavaScript and media playback features, which have eager initialization
  // cost and no plausible use in a sandboxed text renderer that loads only bundled local HTML.
  func disableAllRichFeatures() {
    if preferences.responds(to: sel_getUid("_disableRichJavaScriptFeatures")) {
      preferences.perform(sel_getUid("_disableRichJavaScriptFeatures"))
    }

    if preferences.responds(to: sel_getUid("_disableMediaPlaybackRelatedFeatures")) {
      preferences.perform(sel_getUid("_disableMediaPlaybackRelatedFeatures"))
    }
  }
}

extension EditorConfig {
  static func previewConfig(fileData: Data, theme: String) -> Self {
    .init(
      text: fileData.toString() ?? "",
      theme: theme,
      fontFace: WebFontFace(family: "ui-monospace", weight: nil, style: nil),
      fontSize: 12,
      showLineNumbers: false,
      showActiveLineIndicator: false,
      invisiblesBehavior: .always,
      readOnlyMode: false,
      typewriterMode: false,
      focusMode: false,
      lineWrapping: true,
      lineHeight: 1.4,
      suggestWhileTyping: false,
      standardDirectories: URL.standardDirectories,
      runtimeInfo: nil,
      defaultLineBreak: nil,
      tabKeyBehavior: nil,
      indentUnit: nil,
      localizable: nil,
      // Runtime config from settings.json, not dynamically changeable
      autoCharacterPairs: false,
      indentBehavior: .never,
      headerFontSizeDiffs: nil,
      visibleWhitespaceCharacter: nil,
      visibleLineBreakCharacter: nil,
      searchNormalizers: nil
    )
  }
}
