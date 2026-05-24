//
//  PreviewViewController+Dragging.swift
//  PreviewExtension
//
//  Created by cyan on 5/26/26.
//

import AppKit

/// Dragging behavior in preview extension is wacky.
///
/// Override the event handling and make a homemade scrolling strategy.
extension PreviewViewController {
  func disableDefaultOpen() {
    var node: NSView? = view
    while let current = node {
      for case let recognizer as NSClickGestureRecognizer in current.gestureRecognizers {
        if recognizer.numberOfClicksRequired < 2 {
          continue
        }

        // Disable the default open behavior to enable single clicks
        defaultOpenTarget = recognizer.target
        defaultOpenAction = recognizer.action
        recognizer.isEnabled = false
      }

      node = current.superview
    }
  }

  func addEventMonitorsForDragging() {
    mouseDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
      guard let self, self.overrideDragging(event: event) else {
        return event
      }

      // Dispatch the default open behavior
      if event.clickCount >= 2, let target = self.defaultOpenTarget, let action = self.defaultOpenAction {
        NSApp.sendAction(action, to: target, from: nil)
        return nil
      }

      return self.startDragging(event: event) ? nil : event
    }

    mouseDragMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDragged) { [weak self] event in
      guard let self, self.overrideDragging(event: event) else {
        return event
      }

      self.updateDragging(event: event)
      return nil
    }
  }

  func overrideDragging(event: NSEvent) -> Bool {
    // Don't handle floating windows,
    // which is typically a larger window triggered by pressing spacebar in Finder.
    view.window?.level != .floating && event.window === view.window
  }

  func startDragging(event: NSEvent) -> Bool {
    let location = webView.convert(event.locationInWindow, from: nil)
    let scrollerWidth = NSScroller.scrollerWidth(for: .regular, scrollerStyle: .overlay)

    // Dragging is started only if the click is inside the scroller
    if isRightToLeft ? location.x < scrollerWidth : location.x > view.frame.width - scrollerWidth {
      webView.evaluateJavaScript("startDragging(\(location.y))")
      return true
    } else {
      webView.evaluateJavaScript("cancelDragging()")
      return false
    }
  }

  func updateDragging(event: NSEvent) {
    let location = webView.convert(event.locationInWindow, from: nil)
    webView.evaluateJavaScript("updateDragging(\(location.y))")
  }
}
