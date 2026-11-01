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

    AppDeferredTasks.performWhenReady {
      calls.append(1)
      AppDeferredTasks.performWhenReady {
        calls.append(2)
      }

      XCTAssertEqual(calls, [1, 2])
      AppDeferredTasks.markReady()
    }

    AppDeferredTasks.performWhenReady {
      calls.append(3)
    }

    XCTAssertTrue(calls.isEmpty)
    AppDeferredTasks.markReady()
    XCTAssertEqual(calls, [1, 2, 3])

    AppDeferredTasks.markReady()
    XCTAssertEqual(calls, [1, 2, 3])

    AppDeferredTasks.performWhenReady {
      calls.append(4)
    }

    XCTAssertEqual(calls, [1, 2, 3, 4])
  }
}
