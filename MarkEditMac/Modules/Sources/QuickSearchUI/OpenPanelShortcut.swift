//
//  OpenPanelShortcut.swift
//
//  Created by cyan on 10/11/26.
//

import AppKit

/// Enables the Quick Search shortcut only while the Open panel is active and has no attached sheet.
/// Activation cancels the panel and records the request so the caller can present Quick Search afterward.
/// Call `stop()` when the panel finishes to remove the shortcut and notification observers.
@MainActor
final class OpenPanelShortcut {
  private let panel: NSOpenPanel
  private let register: (@escaping @MainActor @Sendable () -> Void) -> (@MainActor @Sendable () -> Void)?
  private var unregister: (@MainActor @Sendable () -> Void)?
  private var observers: [NSObjectProtocol] = []
  private var isStopped = false
  private(set) var quickSearchRequested = false

  init(
    panel: NSOpenPanel,
    register: @escaping (@escaping @MainActor @Sendable () -> Void) -> (@MainActor @Sendable () -> Void)?
  ) {
    self.panel = panel
    self.register = register

    let application = NSApplication.shared
    let changes: [(Notification.Name, AnyObject?)] = [
      (NSApplication.didBecomeActiveNotification, application),
      (NSWindow.didBecomeKeyNotification, nil),
      (NSWindow.didResignKeyNotification, nil),
      (NSWindow.didEndSheetNotification, panel),
    ]

    let suspensions: [(Notification.Name, AnyObject?)] = [
      (NSApplication.willResignActiveNotification, application),
      (NSWindow.willCloseNotification, panel),
      (NSWindow.willBeginSheetNotification, panel),
    ]

    for (name, object) in changes {
      observers.append(NotificationCenter.default.addObserver(forName: name, object: object, queue: .main) { [weak self] _ in
        MainActor.assumeIsolated {
          guard let self else {
            return
          }

          self.setEnabled(self.isPanelActive)
        }
      })
    }

    for (name, object) in suspensions {
      observers.append(NotificationCenter.default.addObserver(forName: name, object: object, queue: .main) { [weak self] _ in
        MainActor.assumeIsolated {
          self?.setEnabled(false)
        }
      })
    }

    setEnabled(isPanelActive)
  }

  func setEnabled(_ enabled: Bool) {
    guard enabled, !isStopped, !quickSearchRequested else {
      unregister?()
      unregister = nil
      return
    }

    guard unregister == nil else {
      return
    }

    unregister = register { [weak self] in
      guard let self else {
        return
      }

      guard self.isPanelActive else {
        self.setEnabled(false)
        return
      }

      self.quickSearchRequested = true
      self.setEnabled(false)
      self.panel.cancel(nil)
    }
  }

  func stop() {
    isStopped = true
    setEnabled(false)
    observers.forEach(NotificationCenter.default.removeObserver)
    observers = []
  }

  private var isPanelActive: Bool {
    NSApp.isActive && panel.isVisible && panel.isKeyWindow && panel.attachedSheet == nil
  }
}
