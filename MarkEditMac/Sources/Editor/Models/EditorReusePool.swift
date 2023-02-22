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
final class EditorReusePool {
  static let shared = EditorReusePool()
  let processPool = WKProcessPool()

  func warmUp() {
    // The theory here is that loading resources from WKWebViews is expensive,
    // we make a pool that always keeps two instances in memory,
    // if users open more than two editors, it's expected to be slower.
    controllerPool.append(contentsOf: [
      EditorViewController(),
      EditorViewController(),
    ])
  }

  func dequeueViewController() -> EditorViewController {
    if let reusable = controllerPool.first(where: { $0.view.window == nil }) {
      return reusable
    }

    return EditorViewController()
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
