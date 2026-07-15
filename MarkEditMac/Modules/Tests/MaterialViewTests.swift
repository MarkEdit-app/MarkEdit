//
//  MaterialViewTests.swift
//
//  Created by cyan on 6/25/26.
//

import XCTest
import AppKit
@testable import SharedUI

@MainActor
final class MaterialViewTests: XCTestCase {
  /// Mirror the private `Constants` values, kept here as stable contracts.
  private let backdropClassName = "CABackdropLayer"
  private let backdropLayerName = "backdrop"
  private let blurFilterName = "gaussianBlur"

  /// Production discovers the blur backdrop structurally (by its gaussianBlur filter) with no
  /// private ivar names. This guards that the realized layer tree still matches that contract,
  /// and that the inputs we mutate are settable.
  func testStructuralDiscoveryFindsBackdrop() throws {
    let view = makeRealizedView()
    let backdrop = try realizedBackdrop(in: view)

    let names = Set((backdrop.filters ?? []).compactMap {
      ($0 as AnyObject).value(forKey: "name") as? String
    })

    XCTAssert(
      names.contains(blurFilterName),
      "Missing backdrop filter: \(blurFilterName)"
    )

    backdrop.setValue(7.0, forKeyPath: "filters.gaussianBlur.inputRadius")
    XCTAssertEqual(backdrop.value(forKeyPath: "filters.gaussianBlur.inputRadius") as? Double, 7.0)
  }

  /// Production matches the backdrop by three independent traits (filter, name, class) for
  /// resilience. Assert each is present so losing any single trait fails loudly here, while
  /// production still finds the backdrop via the others.
  func testBackdropCarriesAllKnownTraits() throws {
    let view = makeRealizedView()
    let backdrop = try realizedBackdrop(in: view)

    let filterNames = Set((backdrop.filters ?? []).compactMap {
      ($0 as AnyObject).value(forKey: "name") as? String
    })

    XCTAssert(filterNames.contains(blurFilterName), "Backdrop should carry the \(blurFilterName) filter")
    XCTAssertEqual(backdrop.name, backdropLayerName, "Backdrop layer name changed")
    XCTAssertEqual(backdrop.className, backdropClassName, "Backdrop class changed")
  }

  /// The tint overlay paints when a tint color is set, and clears when it's removed.
  func testAppliesTint() {
    let view = MaterialView()
    view.frame = CGRect(x: 0, y: 0, width: 200, height: 100)

    let window = makeWindow()
    window.contentView?.addSubview(view)
    window.makeKeyAndOrderFront(nil)

    view.tintColor = .red
    XCTAssertNotNil(view.tintedView.layerBackgroundColor, "Expected the tint to be applied")

    view.tintColor = nil
    XCTAssertNil(view.tintedView.layerBackgroundColor, "Expected the tint to be cleared")
  }
}

// MARK: - Private

private extension MaterialViewTests {
  func makeWindow() -> NSWindow {
    NSWindow(
      contentRect: CGRect(x: 0, y: 0, width: 200, height: 100),
      styleMask: [.titled],
      backing: .buffered,
      defer: false
    )
  }

  func makeRealizedView() -> EffectView {
    let view = EffectView()
    view.material = .titlebar
    view.frame = CGRect(x: 0, y: 0, width: 200, height: 100)

    let window = makeWindow()
    window.contentView?.addSubview(view)
    window.makeKeyAndOrderFront(nil)

    // Give the visual effect view a chance to build its material layers
    let expectation = XCTestExpectation(description: "Material layer realization")
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { expectation.fulfill() }
    wait(for: [expectation], timeout: 2.0)
    return view
  }

  /// Locates the realized backdrop the same way production does, skipping when the window server
  /// hasn't built the material layer (e.g. a headless test runner).
  func realizedBackdrop(in view: EffectView) throws -> CALayer {
    guard let root = view.layer, let backdrop = firstBackdrop(in: root) else {
      throw XCTSkip("The material backdrop is not realized in this environment")
    }

    return backdrop
  }

  /// Mirror production's multi-trait matching so discovery survives any single trait changing.
  func firstBackdrop(in root: CALayer) -> CALayer? {
    if matchesBackdrop(root) {
      return root
    }

    for sublayer in root.sublayers ?? [] {
      if let found = firstBackdrop(in: sublayer) {
        return found
      }
    }

    return nil
  }

  func matchesBackdrop(_ layer: CALayer) -> Bool {
    let hasBlur = (layer.filters ?? []).contains {
      ($0 as AnyObject).value(forKey: "name") as? String == blurFilterName
    }

    return hasBlur || layer.name == backdropLayerName || layer.className == backdropClassName
  }
}
