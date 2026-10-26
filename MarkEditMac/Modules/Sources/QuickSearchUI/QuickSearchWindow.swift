//
//  QuickSearchWindow.swift
//
//  Created by cyan on 1/17/23.
//

import AppKit

public final class QuickSearchWindow: NSWindow {
  private var resultsConfiguration: QuickSearchResultsConfiguration?
  private var pendingResultsFrame: CGRect?
  private var resizeRevision = 0

  /// Suppresses focus-loss cancellation while the caller transfers focus to an opened result.
  public var isActivatingResult = false {
    didSet {
      (contentView as? QuickSearchView)?.setInteractionEnabled(!isActivatingResult)
    }
  }

  private enum Constants {
    // Values are copied from Xcode
    static let width: Double = 456
    static let height: Double = 48
  }

  /// The handler returns `true` to dismiss the window, or `false` to beep and select the input for correction.
  public init(
    effectViewType: NSView.Type,
    tintColor: NSColor? = nil,
    relativeTo parentRect: CGRect,
    placeholder: String,
    accessibilityHelp: String,
    iconName: String,
    defaultText: String? = nil,
    handler: @escaping (String) -> Bool
  ) {
    let rect = CGRect(
      x: parentRect.minX + (parentRect.width - Constants.width) * 0.5,
      y: parentRect.minY + parentRect.height - Constants.height - 150,
      width: Constants.width,
      height: Constants.height
    )

    super.init(
      contentRect: rect,
      styleMask: .borderless,
      backing: .buffered,
      defer: false
    )

    self.contentView = QuickSearchView(
      effectViewType: effectViewType,
      tintColor: tintColor,
      frame: rect,
      placeholder: placeholder,
      accessibilityHelp: accessibilityHelp,
      iconName: iconName,
      defaultText: defaultText,
      handler: handler
    )

    self.isMovableByWindowBackground = true
    self.isOpaque = false
    self.hasShadow = true
    self.backgroundColor = .clear
  }

  public convenience init(
    effectViewType: NSView.Type,
    tintColor: NSColor? = nil,
    relativeTo parentRect: CGRect,
    visibleFrame: CGRect,
    placeholder: String,
    accessibilityHelp: String,
    iconName: String,
    defaultText: String? = nil,
    results: QuickSearchResultsConfiguration
  ) {
    self.init(
      effectViewType: effectViewType,
      tintColor: tintColor,
      relativeTo: parentRect,
      placeholder: placeholder,
      accessibilityHelp: accessibilityHelp,
      iconName: iconName,
      defaultText: defaultText
    ) { _ in false }

    resultsConfiguration = results
    (contentView as? QuickSearchView)?.configureResults(results)

    let width = min(640, visibleFrame.width - 24)
    let rect = CGRect(
      x: parentRect.midX - width * 0.5,
      y: parentRect.maxY - 248,
      width: width,
      height: 48
    )

    setFrame(rect.clamped(to: visibleFrame.insetBy(dx: 12, dy: 12)), display: false)
  }

  public func updateResults(
    _ items: [QuickSearchItem],
    message: String? = nil,
    preserveSelection: Bool = true
  ) {
    guard let view = contentView as? QuickSearchView, resultsConfiguration != nil else {
      assertionFailure("Results require a results-enabled QuickSearchWindow")
      return
    }

    view.updateResults(
      items,
      message: message,
      preserveSelection: preserveSelection
    )

    let visibleFrame = (screen ?? NSScreen.main)?.visibleFrame ?? frame
    let height = min(48 + view.resultsHeight, visibleFrame.height - 24)
    let anchor = pendingResultsFrame ?? frame
    let rect = CGRect(
      x: anchor.minX,
      y: anchor.maxY - height,
      width: anchor.width,
      height: height
    ).clamped(to: visibleFrame.insetBy(dx: 12, dy: 12))

    guard rect != (pendingResultsFrame ?? frame) else {
      return
    }

    resizeRevision += 1
    let revision = resizeRevision
    pendingResultsFrame = rect

    NSAnimationContext.runAnimationGroup({ context in
      if isVisible && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
        context.duration = 0.15
      } else {
        context.duration = 0
      }

      animator().setFrame(rect, display: true)
    }, completionHandler: { [weak self] in
      Task { @MainActor in
        guard let self, self.resizeRevision == revision else {
          return
        }

        self.pendingResultsFrame = nil
      }
    })
  }

  public func focusInput() {
    (contentView as? QuickSearchView)?.focusInput()
  }

  public func setFilterActive(_ active: Bool) {
    (contentView as? QuickSearchView)?.setFilterActive(active)
  }

  public func setPlaceholder(_ placeholder: String) {
    (contentView as? QuickSearchView)?.setPlaceholder(placeholder)
  }

  override public func performKeyEquivalent(with event: NSEvent) -> Bool {
    if (contentView as? QuickSearchView)?.performFilterKeyEquivalent(with: event) == true {
      return true
    }

    return super.performKeyEquivalent(with: event)
  }

  public var tintColor: NSColor? {
    get {
      (contentView as? QuickSearchView)?.tintColor
    }
    set {
      (contentView as? QuickSearchView)?.tintColor = newValue
    }
  }

  override public var canBecomeKey: Bool {
    true
  }

  override public func resignKey() {
    orderOut(self)
  }

  override public func cancelOperation(_ sender: Any?) {
    isActivatingResult = false
    orderOut(self)
  }

  override public func orderOut(_ sender: Any?) {
    if pendingResultsFrame != nil {
      resizeRevision += 1
      pendingResultsFrame = nil

      NSAnimationContext.runAnimationGroup { context in
        context.duration = 0
        animator().setFrame(frame, display: false)
      }
    }

    let shouldNotify = isVisible && !isActivatingResult
    super.orderOut(sender)

    if shouldNotify {
      resultsConfiguration?.onDismiss()
    }
  }
}

// MARK: - Private

private extension CGRect {
  func clamped(to bounds: CGRect) -> CGRect {
    CGRect(
      x: min(max(minX, bounds.minX), bounds.maxX - width),
      y: min(max(minY, bounds.minY), bounds.maxY - height),
      width: width,
      height: height
    )
  }
}
