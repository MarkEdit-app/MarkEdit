//
//  TextCompletionContext.swift
//
//  Created by cyan on 3/1/23.
//

import AppKit

/**
 Panel interface used to render word completions.
 */
public protocol TextCompletionPanelProtocol {}

/**
 Manages the state of word completions.
 */
@MainActor
public final class TextCompletionContext {
  public var appearance: NSAppearance? {
    get {
      panel.appearance
    }
    set {
      panel.appearance = newValue
    }
  }

  public var isPanelVisible = false {
    didSet {
      if !isPanelVisible {
        panel.orderOut(nil)
        wasFlipped = false
      }
    }
  }

  public var fromIndex: Int = 0
  public var toIndex: Int = 0
  public var selectedText: String { panel.selectedCompletion() }

  public init(localize: TextCompletionLocalizable, commitCompletion: @escaping @Sendable () -> Void) {
    self.localizable = localize
    self.commitCompletion = commitCompletion
  }

  public func updateCompletions(
    _ completions: [String],
    query: String,
    parentWindow: NSWindow,
    caretRect: CGRect
  ) {
    if panel.parent == nil {
      parentWindow.addChildWindow(panel, ordered: .above)
    }

    // Don't make the list absurdly long
    panel.updateCompletions(Array(completions.prefix(50)), query: query)
    panel.selectTop()

    let panelSize = TextCompletionView.panelSize(itemCount: completions.count)
    let safeArea = parentWindow.contentView?.safeAreaInsets.top ?? 0
    let caretPadding: Double = 5
    let panelPadding: Double = 10

    var origin = CGPoint(
      x: caretRect.origin.x - caretPadding,
      y: parentWindow.frame.height - caretRect.maxY - panelSize.height - safeArea - caretPadding
    )

    // Too close to the right
    if origin.x + panelSize.width + panelPadding > parentWindow.frame.size.width {
      origin.x = parentWindow.frame.size.width - panelPadding - panelSize.width
    }

    let screenY = parentWindow.convertPoint(toScreen: origin).y
    let dockHeight = (parentWindow.screen ?? NSScreen.main)?.dockHeight ?? 0

    // Too close to the bottom, or was already upside down during one typing session
    if (screenY - dockHeight - panelPadding < 0) || wasFlipped {
      origin.y = parentWindow.frame.height - caretRect.minY - safeArea + caretPadding
      wasFlipped = true
    }

    let screenOrigin = parentWindow.convertPoint(toScreen: origin)
    panel.setFrame(CGRect(origin: screenOrigin, size: panelSize), display: false)
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

  private lazy var panel = TextCompletionPanel(
    localizable: localizable,
    commitCompletion: commitCompletion
  )

  // The flag to track whether the panel was flipped during a session,
  // as the word gets longer, we will likely see fewer suggestions,
  // we don't want the panel to suddenly flip in this case.
  private var wasFlipped = false

  private let localizable: TextCompletionLocalizable
  private let commitCompletion: @Sendable () -> Void
}

// MARK: - Private

private extension NSScreen {
  var dockHeight: Double {
    frame.height - visibleFrame.height
  }
}
