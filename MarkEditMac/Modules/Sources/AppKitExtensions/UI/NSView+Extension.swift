//
//  NSView+Extension.swift
//
//  Created by cyan on 12/16/22.
//

import AppKit

// MARK: - RTL

public extension NSView {
  /**
   Mirror immediate subviews for RTL languages, we should generally rely on layout anchors,
   but there are certain situations that need frame layout.
   */
  func mirrorImmediateSubviewsIfNeeded(excludedViews: Set<NSView>? = nil) {
    guard NSApp.userInterfaceLayoutDirection == .rightToLeft else {
      return
    }

    for subview in subviews {
      if excludedViews?.contains(subview) == true {
        continue
      }

      mirrorImmediateSubviewIfNeeded(subview)
    }
  }

  func mirrorImmediateSubviewIfNeeded(_ subview: NSView) {
    guard NSApp.userInterfaceLayoutDirection == .rightToLeft else {
      return
    }

    guard subview.superview == self else {
      fatalError("\(subview) is not a subview of \(self), cannot mirror its layout")
    }

    subview.frame.origin.x = bounds.size.width - (subview.frame.origin.x + subview.frame.size.width)
  }
}

// MARK: - Helpers

public extension NSView {
  var layerBackgroundColor: NSColor? {
    get {
      guard wantsLayer, let cgColor = layer?.backgroundColor else {
        return nil
      }

      return NSColor(cgColor: cgColor)
    }
    set {
      wantsLayer = true
      layer?.backgroundColor = newValue?.resolvedColor(with: effectiveAppearance).cgColor
    }
  }

  var hasUnfinishedAnimations: Bool {
    layer?.animationKeys()?.isEmpty == false
  }

  var isFirstResponder: Bool {
    isFirstResponder(in: window)
  }

  /// Check if the view itself or one of its descendants is the first responder in a window.
  func isFirstResponder(in window: NSWindow?) -> Bool {
    (window?.firstResponder as? NSView)?.belongs(to: self) ?? false
  }

  /// Check if the view is a child of another view, or is another view.
  func belongs(to view: NSView) -> Bool {
    var node: NSView? = self
    while node != nil {
      if node == view {
        return true
      }
      node = node?.superview
    }

    return false
  }

  func update(_ animated: Bool = true) -> Self {
    animated ? animator() : self
  }

  /// Transform the view to a scale while keeping it centered during the animation.
  func scaleTo(_ scale: Double, duration: TimeInterval = 0.3, completion: (() -> Void)? = nil) {
    wantsLayer = true
    layer?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    layer?.position = CGPoint(x: frame.midX, y: frame.midY)

    CATransaction.begin()
    CATransaction.setAnimationDuration(duration)
    CATransaction.setCompletionBlock { completion?() }

    let animation = CABasicAnimation(keyPath: "transform")
    animation.fromValue = layer?.presentation()?.transform ?? layer?.transform

    let transform = CATransform3DMakeScale(scale, scale, 1)
    animation.toValue = transform
    animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

    layer?.transform = transform
    layer?.add(animation, forKey: "scale")
    CATransaction.commit()
  }

  /// Enumerate all descendants, recursively, self first.
  func enumerateDescendants<T: NSView>(where: ((T) -> Bool)? = nil, handler: (T) -> Void) {
    if let view = self as? T, `where`?(view) ?? true {
      handler(view)
    }

    subviews.forEach {
      $0.enumerateDescendants(where: `where`, handler: handler)
    }
  }

  /// Returns the first descendant that matches a predicate, self is included.
  func firstDescendant<T: NSView>(where: ((T) -> Bool)? = nil) -> T? {
    var stack = [self]
    while !stack.isEmpty {
      let node = stack.removeLast()
      if let view = node as? T, `where`?(view) ?? true {
        return view
      }

      // Depth-first search
      stack.append(contentsOf: node.subviews)
    }

    return nil
  }
}
