//
//  PreviewViewWebView.swift
//  PreviewExtension
//
//  Created by cyan on 5/26/26.
//

import WebKit
import MarkEditCore

final class PreviewViewWebView: WKWebView {
  override init(frame: CGRect, configuration: WKWebViewConfiguration) {
    super.init(frame: frame, configuration: configuration)
    disableWindowOcclusionDetection()
    allowsMagnification = true
    isInspectable = true
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func willOpenMenu(_ menu: NSMenu, with event: NSEvent) {
    menu.items.forEach {
      if hiddenMenuTags.contains($0.tag) {
        $0.isHidden = true
      }
    }

    super.willOpenMenu(menu, with: event)
  }
}

// WKContextMenuItemTag values we don't want surfaced in the preview.
//
// See: https://github.com/WebKit/WebKit/blob/main/Source/WebKit/Shared/API/c/WKContextMenuItemTypes.h
private let hiddenMenuTags: Set<Int> = [
  1,   // OpenLinkInNewWindow
  2,   // DownloadLinkToDisk
  4,   // OpenImageInNewWindow
  5,   // DownloadImageToDisk
  12,  // Reload
  21,  // SearchWeb
  33,  // OpenLink
  102, // CopyLinkWithHighlight
]
