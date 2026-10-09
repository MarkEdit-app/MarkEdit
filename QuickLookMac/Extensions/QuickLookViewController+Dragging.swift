//
//  QuickLookViewController+Dragging.swift
//  QuickLookMac
//
//  Created by cyan on 5/26/26.
//

import AppKit
import OSLog

final class QuickLookOpenGestureRecognizer: NSClickGestureRecognizer {
  override func mouseUp(with event: NSEvent) {
    super.mouseUp(with: event)
    // After delivering the first click, withhold the next while opening is pending
    if state == .possible {
      delaysPrimaryMouseButtonEvents = true
    }
  }

  override func reset() {
    super.reset()
    delaysPrimaryMouseButtonEvents = false
  }
}

/// Dragging behavior in the QuickLook extension is wacky.
///
/// Coordinate opening and scrollbar gestures with WebKit's content gestures.
extension QuickLookViewController {
  func configureDefaultOpen() {
    var node: NSView? = view
    while let current = node {
      for case let recognizer as NSClickGestureRecognizer in current.gestureRecognizers {
        if recognizer === openRecognizer || recognizer.numberOfClicksRequired < 2 {
          continue
        }

        // Suppress host opening in both modes; our recognizer gates forwarding.
        defaultOpenTarget = recognizer.target
        defaultOpenAction = recognizer.action
        recognizer.isEnabled = false
      }

      node = current.superview
    }
  }

  func configureGestures() {
    openRecognizer.numberOfClicksRequired = 2
    openRecognizer.delaysPrimaryMouseButtonEvents = false
    scrollbarDragRecognizer.delaysPrimaryMouseButtonEvents = true

    if #available(macOS 27.0, *) {
      openRecognizer.isCancellableByScrollGesture = true
      scrollbarClickRecognizer.isCancellableByScrollGesture = true
      scrollbarDragRecognizer.minimumNumberOfTouches = 1
      scrollbarDragRecognizer.maximumNumberOfTouches = 1
    }

    for recognizer in [openRecognizer, scrollbarClickRecognizer, scrollbarDragRecognizer] {
      recognizer.allowedTouchTypes = .direct
      recognizer.delegate = self
      webView.addGestureRecognizer(recognizer)
    }
  }
}

// MARK: - Gesture Actions

extension QuickLookViewController {
  @objc func openPreview(_ recognizer: NSClickGestureRecognizer) {
    guard shouldOpenOnDoubleClick, recognizer.state == .ended else {
      return
    }

    gestureLogger.debug("Recognized Quick Look open gesture")
    guard let target = defaultOpenTarget, let action = defaultOpenAction else {
      gestureLogger.error("Cannot open Quick Look preview: missing host action")
      return
    }

    if !NSApp.sendAction(action, to: target, from: nil) {
      gestureLogger.error("Failed to dispatch Quick Look host open action")
    }
  }

  @objc func clickScrollbar(_ recognizer: NSClickGestureRecognizer) {
    guard recognizer.state == .ended else {
      return
    }

    startDragging(at: recognizer.location(in: webView))
    cancelDragging()
  }

  @objc func dragScrollbar(_ recognizer: NSPanGestureRecognizer) {
    switch recognizer.state {
    case .began:
      let current = recognizer.location(in: webView)
      let translation = recognizer.translation(in: webView)
      startDragging(at: CGPoint(x: current.x - translation.x, y: current.y - translation.y))
      updateDragging(at: current)
    case .changed:
      updateDragging(at: recognizer.location(in: webView))
    case .ended:
      updateDragging(at: recognizer.location(in: webView))
      cancelDragging()
    case .cancelled, .failed:
      cancelDragging()
    default:
      break
    }
  }
}

// MARK: - Gesture Recognition

extension QuickLookViewController: NSGestureRecognizerDelegate {
  func gestureRecognizer(
    _ gestureRecognizer: NSGestureRecognizer,
    shouldAttemptToRecognizeWith event: NSEvent
  ) -> Bool {
    guard event.type == .leftMouseDown, event.window === view.window else {
      return false
    }

    return shouldRecognize(gestureRecognizer, at: webView.convert(event.locationInWindow, from: nil))
  }

  func gestureRecognizer(
    _ gestureRecognizer: NSGestureRecognizer,
    shouldReceive touch: NSTouch
  ) -> Bool {
    guard view.window != nil, touch.type == .direct else {
      return false
    }

    return shouldRecognize(gestureRecognizer, at: touch.location(in: webView))
  }

  func gestureRecognizer(
    _ gestureRecognizer: NSGestureRecognizer,
    shouldBeRequiredToFailBy otherGestureRecognizer: NSGestureRecognizer
  ) -> Bool {
    if gestureRecognizer === openRecognizer, !shouldOpenOnDoubleClick {
      return false
    }

    // A scrollbar click must wait until dragging has been ruled out
    if otherGestureRecognizer === scrollbarClickRecognizer {
      return gestureRecognizer === scrollbarDragRecognizer
    }

    if otherGestureRecognizer === scrollbarDragRecognizer || otherGestureRecognizer === openRecognizer {
      return false
    }

    // WebKit's scrolling and text selection must wait for our accepted gesture
    guard let otherView = otherGestureRecognizer.view else {
      return false
    }

    return otherView === webView || otherView.isDescendant(of: webView)
  }
}

// MARK: - Coordinates and Hit Testing

private extension QuickLookViewController {
  func shouldRecognize(_ recognizer: NSGestureRecognizer, at location: CGPoint) -> Bool {
    guard view.window != nil, webView.bounds.contains(location) else {
      return false
    }

    let inScroller = isInScroller(location)
    return recognizer === openRecognizer ? shouldOpenOnDoubleClick && !inScroller : inScroller
  }

  var shouldOpenOnDoubleClick: Bool {
    // Spacebar previews keep double-click text selection instead of opening
    guard let window = view.window else {
      return false
    }

    return window.level != .floating
  }

  func isInScroller(_ location: CGPoint) -> Bool {
    let bounds = webView.bounds
    guard bounds.contains(location) else {
      return false
    }

    let width = NSScroller.scrollerWidth(for: .regular, scrollerStyle: .overlay)
    return isRightToLeft ? location.x < bounds.minX + width : location.x > bounds.maxX - width
  }

  func startDragging(at location: CGPoint) {
    webView.evaluateJavaScript("startDragging(\(location.y))")
  }

  func updateDragging(at location: CGPoint) {
    webView.evaluateJavaScript("updateDragging(\(location.y))")
  }

  func cancelDragging() {
    webView.evaluateJavaScript("cancelDragging()")
  }
}

private let gestureLogger = Logger(subsystem: "app.cyan.markedit", category: "QuickLookGestures")
