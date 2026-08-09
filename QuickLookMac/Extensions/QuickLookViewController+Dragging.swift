//
//  QuickLookViewController+Dragging.swift
//  QuickLookMac
//
//  Created by cyan on 5/26/26.
//

import AppKit

/// Dragging behavior in the QuickLook extension is wacky.
///
/// Override the event handling and make a homemade scrolling strategy.
extension QuickLookViewController {
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

      self.isDraggingScroller = false
      if event.clickCount >= 2, let target = self.defaultOpenTarget, let action = self.defaultOpenAction {
        // Dispatch the default open behavior
        NSApp.sendAction(action, to: target, from: nil)
        return nil
      }

      self.isDraggingScroller = self.startDragging(event: event)
      return self.isDraggingScroller ? nil : event
    }

    mouseDragMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDragged) { [weak self] event in
      guard let self, self.overrideDragging(event: event), self.isDraggingScroller else {
        return event
      }

      self.updateDragging(event: event)
      return nil
    }

    mouseUpMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseUp) { [weak self] event in
      guard let self, self.isDraggingScroller else {
        return event
      }

      self.isDraggingScroller = false
      self.cancelDragging()
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
      cancelDragging()
      return false
    }
  }

  func updateDragging(event: NSEvent) {
    let location = webView.convert(event.locationInWindow, from: nil)
    webView.evaluateJavaScript("updateDragging(\(location.y))")
  }

  func cancelDragging() {
    webView.evaluateJavaScript("cancelDragging()")
  }
}
