//
//  EditorReusePool.swift
//  MarkEditMac
//
//  Created by cyan on 12/15/22.
//

import AppKit
import WebKit
import MarkEditKit

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
    startObservingMemoryPressure()

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
  private var memoryPressureSource: DispatchSourceMemoryPressure?

  private init() {}

  private func startObservingMemoryPressure() {
    let source = DispatchSource.makeMemoryPressureSource(eventMask: .critical, queue: .main)
    source.setEventHandler { [weak self] in
      Task { @MainActor in
        self?.preloadedController = nil
        Logger.log(.info, "Releasing preloaded editor on memory pressure")
      }
    }

    source.resume()
    memoryPressureSource = source
  }
}
