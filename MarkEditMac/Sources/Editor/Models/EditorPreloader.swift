//
//  EditorPreloader.swift
//  MarkEditMac
//
//  Created by cyan on 12/15/22.
//

import AppKit
import WebKit
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

    startObservingMemoryPressure()

    // Try if warmup can fix the empty suggestion bug,
    // defer to avoid blocking the critical launch path.
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
      NSSpellChecker.shared.checkSpelling(of: "warmup", startingAt: 0)
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
