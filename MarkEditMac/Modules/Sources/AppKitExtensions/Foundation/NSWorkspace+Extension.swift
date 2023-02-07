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
}
