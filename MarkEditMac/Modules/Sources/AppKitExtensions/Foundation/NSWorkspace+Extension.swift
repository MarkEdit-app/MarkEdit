//
//  NSWorkspace+Extension.swift
//
//  Created by cyan on 1/21/23.
//

import AppKit

public extension NSWorkspace {
  func openTerminal(preferredIdentifier: String? = nil) {
    let identifiers = [
      preferredIdentifier,      // User configured
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
    ].compactMap { $0 }

    if let url = identifiers.compactMap({ urlForApplication(withBundleIdentifier: $0) }).first {
      openApplication(at: url, configuration: Self.OpenConfiguration())
    }
  }

  /// Open the URL if we can, otherwise reveal it in Finder.
  ///
  /// The return value indicates whether it's successfully opened or revealed.
  @discardableResult
  func openOrReveal(url: URL) -> Bool {
    guard url.scheme == "file" else {
      // Directly open non-local URLs
      return open(url)
    }

    // Get the standardized version of local URLs
    let url = url.standardized

    // Try opening first; the system can route the file to the registered handler
    // even when the current sandboxed process can't read it directly.
    if open(url) {
      return true
    }

    // Fall back to revealing in Finder if the file exists but couldn't be opened
    if FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) {
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
