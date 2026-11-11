//
//  AppDeferredTasksTests.swift
//
//  Created by cyan on 11/1/26.
//

import XCTest
@testable import MarkEdit

@MainActor
final class AppDeferredTasksTests: XCTestCase {
  func testLaunchLifecycle() {
    var calls: [Int] = []

    AppDeferredTasks.performWhenReady(stage: .firstWindowBecameKey) {
      calls.append(5)
      AppDeferredTasks.performWhenReady(stage: .firstWindowBecameKey) {
        calls.append(6)
      }

      XCTAssertEqual(calls, [1, 2, 3, 4, 5, 6])
      AppDeferredTasks.markReady(stage: .firstWindowBecameKey)
    }

    AppDeferredTasks.performWhenReady(stage: .appFinishedLaunching) {
      calls.append(1)
      AppDeferredTasks.performWhenReady(stage: .appFinishedLaunching) {
        calls.append(2)
      }

      XCTAssertEqual(calls, [1, 2])
      AppDeferredTasks.markReady(stage: .appFinishedLaunching)
    }

    AppDeferredTasks.performWhenReady(stage: .appFinishedLaunching) {
      calls.append(3)
    }

    XCTAssertTrue(calls.isEmpty)
    AppDeferredTasks.markReady(stage: .appFinishedLaunching)
    XCTAssertEqual(calls, [1, 2, 3])

    AppDeferredTasks.markReady(stage: .appFinishedLaunching)
    XCTAssertEqual(calls, [1, 2, 3])

    AppDeferredTasks.performWhenReady(stage: .appFinishedLaunching) {
      calls.append(4)
    }

    AppDeferredTasks.performWhenReady(stage: .firstWindowBecameKey) {
      calls.append(7)
    }

    XCTAssertEqual(calls, [1, 2, 3, 4])
    AppDeferredTasks.markReady(stage: .firstWindowBecameKey)
    XCTAssertEqual(calls, [1, 2, 3, 4, 5, 6, 7])

    AppDeferredTasks.markReady(stage: .appFinishedLaunching)
    AppDeferredTasks.markReady(stage: .firstWindowBecameKey)
    XCTAssertEqual(calls, [1, 2, 3, 4, 5, 6, 7])

    AppDeferredTasks.performWhenReady(stage: .firstWindowBecameKey) {
      calls.append(8)
    }

    AppDeferredTasks.performWhenReady(stage: .appFinishedLaunching) {
      calls.append(9)
    }

    XCTAssertEqual(calls, [1, 2, 3, 4, 5, 6, 7, 8, 9])
  }
}
