//
//  EditorPreloader.swift
//  MarkEditMac
//
//  Created by cyan on 12/15/22.
//

import AppKit
import MarkEditKit

/**
 Preloads an `EditorViewController` so the next document can open without paying the WebView load cost.
 */
@MainActor
final class EditorPreloader {
  static let shared = EditorPreloader()

  func warmUp() {
    // Start loading an editor early so prepareViewController() can return faster.
    Task {
      await prepareViewController()
    }
  }

  /// Ensure the preloaded controller has finished loading,
  /// call this before ``takeViewController()`` to guarantee readiness.
  func prepareViewController() async {
    if preloadedController == nil {
      preloadedController = EditorViewController()
    }

    await preloadedController?.waitUntilLoaded()
  }

  func takeViewController() -> EditorViewController {
    let controller = preloadedController ?? EditorViewController()
    preloadedController = EditorViewController(preloadDelay: 0.2)

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
