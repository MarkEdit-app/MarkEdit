//
//  AppDeferredTasks.swift
//  MarkEditMac
//
//  Created by cyan on 11/1/26.
//

@MainActor
enum AppDeferredTasks {
  enum Stage {
    case appFinishedLaunching
    case firstWindowBecameKey
  }

  private static var readyStages: Set<Stage> = []
  private static var pending: [Stage: [@MainActor () -> Void]] = [:]

  /// Opens only the given stage's gate; call this after its lifecycle event.
  static func markReady(stage: Stage) {
    guard readyStages.insert(stage).inserted else {
      return
    }

    // Open the gate before draining so reentrant calls execute normally
    let actions = pending.removeValue(forKey: stage)
    actions?.forEach { $0() }
  }

  static func performWhenReady(stage: Stage, _ action: @escaping @MainActor () -> Void) {
    if readyStages.contains(stage) {
      action()
    } else {
      pending[stage, default: []].append(action)
    }
  }
}
