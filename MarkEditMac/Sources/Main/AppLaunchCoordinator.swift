//
//  AppLaunchCoordinator.swift
//  MarkEditMac
//
//  Created by cyan on 11/1/26.
//

@MainActor
enum AppLaunchCoordinator {
  private static var isReady = false
  private static var pending: [@MainActor () -> Void] = []

  static func markReady() {
    guard !isReady else {
      return
    }

    // Open the gate before draining so reentrant calls execute normally
    isReady = true
    let actions = pending
    pending.removeAll()
    actions.forEach { $0() }
  }

  static func performWhenReady(_ action: @escaping @MainActor () -> Void) {
    if isReady {
      action()
    } else {
      pending.append(action)
    }
  }
}
