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
      if !isPanelVisible {
        panel.orderOut(nil)
      }
    }
  }

  public var fromIndex: Int = 0
  public var toIndex: Int = 0
  public var selectedText: String { panel.selectedCompletion() }

  public init(localize: TextCompletionLocalizable) {
    self.localizable = localize
  }

  public func updateCompletions(_ completions: [String], parentWindow: NSWindow, caretRect: CGRect) {
    if panel.parent == nil {
      parentWindow.addChildWindow(panel, ordered: .above)
    }

    panel.updateCompletions(Array(completions.prefix(50)))
    panel.selectTop()

    let size = CGSize(
      width: 120,
      height: Double(min(8, completions.count)) * UIConstants.itemHeight + 2 * UIConstants.itemPadding
    )

    let safeArea = parentWindow.contentView?.safeAreaInsets.top ?? 0
    let caretPadding: Double = 5
    let panelPadding: Double = 10

    var origin = CGPoint(
      x: caretRect.origin.x - caretPadding,
      y: parentWindow.frame.height - caretRect.maxY - size.height - safeArea - caretPadding
    )

    // Too right
    if origin.x + size.width + panelPadding > parentWindow.frame.size.width {
      origin.x = parentWindow.frame.size.width - panelPadding - size.width
    }

    // Too bottom
    if origin.y - panelPadding < 0 {
      origin.y = parentWindow.frame.height - caretRect.minY - safeArea + caretPadding
    }

    let screenOrigin = parentWindow.convertPoint(toScreen: origin)
    panel.setFrame(CGRect(origin: screenOrigin, size: size), display: false)
    panel.orderFront(nil)
  }

  public func selectPrevious() {
    panel.selectPrevious()
  }

  public func selectNext() {
    panel.selectNext()
  }

  public func selectTop() {
    panel.selectTop()
  }

  public func selectBottom() {
    panel.selectBottom()
  }

  // MARK: - Private

  private let localizable: TextCompletionLocalizable
  private lazy var panel = TextCompletionPanel(localizable: localizable)
}
