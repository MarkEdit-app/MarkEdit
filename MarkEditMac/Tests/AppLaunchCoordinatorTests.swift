//
//  AppLaunchCoordinatorTests.swift
//
//  Created by cyan on 11/1/26.
//

import XCTest
@testable import MarkEdit

@MainActor
final class AppLaunchCoordinatorTests: XCTestCase {
  func testLaunchLifecycle() {
    var calls: [Int] = []

    AppLaunchCoordinator.performWhenReady {
      calls.append(1)
      AppLaunchCoordinator.performWhenReady {
        calls.append(2)
      }

      XCTAssertEqual(calls, [1, 2])
      AppLaunchCoordinator.markReady()
    }

    AppLaunchCoordinator.performWhenReady {
      calls.append(3)
    }

    XCTAssertTrue(calls.isEmpty)
    AppLaunchCoordinator.markReady()
    XCTAssertEqual(calls, [1, 2, 3])

    AppLaunchCoordinator.markReady()
    XCTAssertEqual(calls, [1, 2, 3])

    AppLaunchCoordinator.performWhenReady {
      calls.append(4)
    }

    XCTAssertEqual(calls, [1, 2, 3, 4])
  }
}
