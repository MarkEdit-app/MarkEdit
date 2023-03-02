//
//  TextCompletionContext.swift
//
//  Created by cyan on 3/1/23.
//

import AppKit

/**
 Manages the state of text completions.
 */
public final class TextCompletionContext {
  public var isPanelVisible = false {
    didSet {
      if isPanelVisible {
        panel.orderFront(nil)
      } else {
        panel.orderOut(nil)
      }
    }
  }

  public init() {}

  public func updateCompletions(_ completions: [String], parentWindow: NSWindow, caretRect: CGRect) {
    if panel.parent == nil {
      parentWindow.addChildWindow(panel, ordered: .above)
    }

    let size = CGSize(
      width: 200,
      height: 200
    )

    let offset = parentWindow.contentView?.safeAreaInsets.top ?? 0
    let origin = parentWindow.convertPoint(toScreen: CGPoint(
      x: caretRect.origin.x,
      y: parentWindow.frame.height - caretRect.maxY - size.height - offset
    ))

    panel.setFrame(CGRect(origin: origin, size: size), display: false)
  }

  // MARK: - Private

  private let panel = TextCompletionPanel()
}
