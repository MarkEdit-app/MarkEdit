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
  let processPool = WKProcessPool()

  func warmUp() {
    if controllerPool.isEmpty {
      controllerPool.append(EditorViewController())
    }

    // Try if warmup can fix the empty suggestion bug
    NSSpellChecker.shared.checkSpelling(of: "warmup", startingAt: 0)
  }

  func dequeueViewController() -> EditorViewController {
    if let reusable = (controllerPool.first { $0.view.window == nil }) {
      return reusable
    }

    let controller = EditorViewController()
    if controllerPool.count < 2 {
      // The theory here is that loading resources from WKWebViews is expensive,
      // we make a pool that always keeps two instances in memory,
      // if users open more than two editors, it's expected to be slower.
      controllerPool.append(controller)
    }

    return controller
  }

  /// All editors, whether with or without a visible window.
  func viewControllers() -> [EditorViewController] {
    controllerPool + {
      let windows = NSApplication.shared.windows.compactMap { $0 as? EditorWindow }
      let controllers = windows.compactMap { $0.contentViewController as? EditorViewController }
      return controllers.filter { !controllerPool.contains($0) }
    }()
  }

  // MARK: - Private

  private var controllerPool = [EditorViewController]()

  private init() {}
}
