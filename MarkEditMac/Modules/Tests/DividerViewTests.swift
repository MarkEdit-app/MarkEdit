//
//  DividerViewTests.swift
//
//  Created by cyan on 10/9/26.
//

import AppKit
import XCTest
@testable import SharedUI

@MainActor
final class DividerViewTests: XCTestCase {
  func testDividerIgnoresHitTesting() {
    let divider = DividerView()
    divider.frame = CGRect(x: 0, y: 0, width: 100, height: 1)

    XCTAssertNil(divider.hitTest(CGPoint(x: 50, y: 0.5)))
  }

  func testDividerDoesNotBlockUnderlyingButton() throws {
    let container = NSView(frame: CGRect(x: 0, y: 0, width: 100, height: 24))
    let button = NSButton(frame: container.bounds)
    let divider = DividerView()
    divider.frame = CGRect(x: 49.5, y: 0, width: 1, height: 24)
    container.addSubview(button)
    container.addSubview(divider)

    let hit = try XCTUnwrap(container.hitTest(CGPoint(x: 50, y: 12)))
    XCTAssertTrue(hit === button || hit.isDescendant(of: button))
  }

  func testRoundedButtonGroupDividerPreservesBothButtonTargets() throws {
    let leftButton = NonBezelButton(frame: .zero)
    let rightButton = NonBezelButton(frame: .zero)
    let group = RoundedButtonGroup(leftButton: leftButton, rightButton: rightButton)
    group.frame = CGRect(x: 0, y: 0, width: 100, height: 24)
    group.isEnabled = true
    group.layout()

    for (x, button) in [(49.75, leftButton), (50.25, rightButton)] {
      let hit = try XCTUnwrap(group.hitTest(CGPoint(x: x, y: 12)))
      XCTAssertTrue(hit === button || hit.isDescendant(of: button))
    }

    group.isEnabled = false
    XCTAssertNil(group.hitTest(CGPoint(x: 50, y: 12)))
  }
}
