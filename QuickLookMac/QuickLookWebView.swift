//
//  QuickLookWebView.swift
//  QuickLookMac
//
//  Created by cyan on 5/26/26.
//

import WebKit
import MarkEditCore

final class QuickLookWebView: WKWebView {
  override init(frame: CGRect, configuration: WKWebViewConfiguration) {
    super.init(frame: frame, configuration: configuration)
    disableWindowOcclusionDetection()
    allowsMagnification = false // Rely on `enablePinchZoom()` instead
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

    if window?.level == .floating {
      menu.addItem(.separator())
      menu.addItem(resetWindowSizeItem())
    }

    super.willOpenMenu(menu, with: event)
  }
}

// MARK: - Contextual Menu

private extension QuickLookWebView {
  private func resetWindowSizeItem() -> NSMenuItem {
    let item = NSMenuItem(
      title: String(
        localized: "Reset Window Size",
        comment: "Menu item to reset the Quick Look window size"
      ),
      action: #selector(resetWindowSizeAction),
      keyEquivalent: ""
    )

    item.subtitle = String(
      localized: "Takes effect after relaunching Quick Look",
      comment: "Subtitle explaining when the Quick Look window size reset takes effect"
    )

    item.target = self
    item.isEnabled = QuickLookWindowSize.savedValue != nil
    return item
  }

  @objc private func resetWindowSizeAction() {
    QuickLookWindowSize.savedValue = nil
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
  84,  // PlayAllAnimations
  85,  // PauseAllAnimations
  102, // CopyLinkWithHighlight
]
