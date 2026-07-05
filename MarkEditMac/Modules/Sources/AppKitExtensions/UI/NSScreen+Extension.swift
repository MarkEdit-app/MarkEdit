//
//  NSScreen+Extension.swift
//
//  Created by cyan on 7/5/26.
//

import AppKit

public extension NSScreen {
  @MainActor static var preferredScale: CGFloat {
    preferredScreen?.backingScaleFactor ?? 1.0
  }
}

// MARK: - Private

private extension NSScreen {
  @MainActor static var preferredScreen: NSScreen? {
    (NSApp.keyWindow ?? NSApp.mainWindow)?.screen ?? .main
  }
}
