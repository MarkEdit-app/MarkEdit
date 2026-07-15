//
//  EffectView.swift
//
//  Created by cyan on 6/27/26.
//

import AppKit
import AppKitExtensions

/**
 `NSVisualEffectView` that adjusts the system backdrop blur radius.

 The adjustment is applied to the discovered backdrop layers and safely no-ops when the
 system filter is absent.
 */
public class EffectView: NSVisualEffectView {
  /// Backdrop blur radius; a nil value keeps the system default.
  var backdropBlur: Double? {
    didSet {
      needsDisplay = true
    }
  }

  // swiftlint:disable:next prohibited_super_call
  override public func updateLayer() {
    super.updateLayer()
    applyEffects()
  }

  override public func layout() {
    super.layout()
    applyEffects()
  }
}

// MARK: - Private

private extension EffectView {
  enum Constants {
    static let backdropClassName = "CABackdropLayer"
    static let backdropLayerName = "backdrop"
    static let blurFilterName = "gaussianBlur"
  }

  func applyEffects() {
    // Find the blur backdrops, which avoids private layer ivars (e.g. the macOS 27 `_impl`
    // renderer) and covers both active and inactive.
    let backdrops = layer?.layers {
      $0.hasFilter(named: Constants.blurFilterName) ||
      $0.className == Constants.backdropClassName ||
      $0.name == Constants.backdropLayerName
    } ?? []

    for backdrop in backdrops {
      backdrop.setFilterValue(
        backdropBlur,
        filterNamed: Constants.blurFilterName,
        key: "inputRadius"
      )
    }
  }
}
