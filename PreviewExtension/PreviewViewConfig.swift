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

  var userScripts: [WKUserScript] {
    sharedAssets(directory: "Shared/scripts", types: ["js"]).map { url, contents in
      WKUserScript(
        source: EditorUserAsset.script(for: url, contents: contents),
        injectionTime: .atDocumentEnd,
        forMainFrameOnly: false
      )
    }
  }

  var userStyles: [String] {
    sharedAssets(directory: "Shared/styles", types: ["css"]).map { url, contents in
      EditorUserAsset.style(for: url, contents: contents)
    }
  }

  private func sharedAssets(directory: String, types: Set<String>) -> [(URL, String)] {
    guard let baseURL = URL.sharedContainerURL?.appending(path: directory, directoryHint: .isDirectory) else {
      return []
    }

    return baseURL.sortedFiles(types: types).compactMap { url in
      guard let contents = (try? Data(contentsOf: url))?.toString(), !contents.isEmpty else {
        return nil
      }

      return (url, contents)
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
  static func previewConfig(fileData: Data) -> Self {
    .init(
      text: fileData.toString() ?? "",
      theme: "github-light", // Ignored by @light editor
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
