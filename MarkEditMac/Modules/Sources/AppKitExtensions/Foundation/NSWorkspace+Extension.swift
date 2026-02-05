//
//  NSWorkspace+Extension.swift
//
//  Created by cyan on 1/21/23.
//

import AppKit

public extension NSWorkspace {
  func openTerminal() {
    let identifiers = [
      "com.googlecode.iterm2",  // iTerm2
      "com.mitchellh.ghostty",  // Ghostty
      "dev.warp.Warp-Stable",   // Warp
      "com.github.wez.wezterm", // WezTerm
      "com.eltima.cmd1",        // Commander One
      "com.csw.macwise",        // MacWise
      "net.kovidgoyal.kitty",   // Kitty
      "co.zeit.hyper",          // Hyper
      "co.byobu",               // Byobu
      "net.macterm.MacTerm",    // MacTerm
      "org.alacritty",          // Alacritty
      "com.emtec.zoc8",         // Zoc
      "org.tabby",              // Tabby
      "com.apple.Terminal",     // Terminal
    ]

    if let url = identifiers.compactMap({ urlForApplication(withBundleIdentifier: $0) }).first {
      openApplication(at: url, configuration: Self.OpenConfiguration())
    }
  }

  /// Open the URL if we can, otherwise reveal it in Finder.
  ///
  /// The return value indicates whether it's successfully opened or revealed.
  @discardableResult
  func openOrReveal(url: URL) -> Bool {
    // It's not a local file or we have read access, we just open it
    guard url.scheme == "file" && !FileManager.default.isReadableFile(atPath: url.path) else {
      return open(url)
    }

    // Otherwise, we can only reveal it in Finder
    if FileManager.default.fileExists(atPath: url.path) {
      activateFileViewerSelecting([url])
      return true
    }

    return false
  }

  @discardableResult
  func safelyOpenURL(string: String) -> Bool {
    guard let url = URL(string: string) else {
      assertionFailure("Failed to create the URL: \(string)")
      return false
    }

    return open(url)
  }
}
