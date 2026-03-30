//
//  EditorReusePool.swift
//  MarkEditMac
//
//  Created by cyan on 12/15/22.
//

import AppKit
import WebKit

/**
 Reuse pool for editors to keep WebViews in memory.
 */
@MainActor
final class EditorReusePool {
  static let shared = EditorReusePool()

  func warmUp() {
    // Pre-load an instance so the first dequeue uses it,
    // subsequent dequeues rotate the preloaded controller.
    preloadedController = EditorViewController()

    // Try if warmup can fix the empty suggestion bug,
    // defer to avoid blocking the critical launch path.
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
      NSSpellChecker.shared.checkSpelling(of: "warmup", startingAt: 0)
    }
  }

  func dequeueViewController() -> EditorViewController {
    let controller = preloadedController ?? EditorViewController()
    preloadedController = EditorViewController()

    return controller
  }

  /// All editors, whether with or without a visible window.
  func viewControllers() -> [EditorViewController] {
    let windows = NSApp.windows.compactMap {
      $0 as? EditorWindow
    }

    let controllers = windows.compactMap {
      $0.contentViewController as? EditorViewController
    }

    return controllers.filter { $0 !== preloadedController } + [preloadedController].compactMap { $0 }
  }

  // MARK: - Private

  private var preloadedController: EditorViewController?

  private init() {}
}
