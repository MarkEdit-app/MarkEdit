//
//  MaterialView.swift
//
//  Created by cyan on 6/25/26.
//

import AppKit
import AppKitExtensions

/**
 Visual effect view with a tinted layer.
 */
public class MaterialView: NSView {
  private let effectView = NSVisualEffectView()
  private let tintedView = NSView()

  public var material: NSVisualEffectView.Material {
    get {
      effectView.material
    }
    set {
      effectView.material = newValue
    }
  }

  public var tintColor: NSColor? {
    get {
      tintedView.layerBackgroundColor
    }
    set {
      tintedView.layerBackgroundColor = newValue
    }
  }

  public init() {
    super.init(frame: .zero)
    addSubview(effectView)
    addSubview(tintedView)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func layout() {
    super.layout()

    effectView.frame = bounds
    tintedView.frame = bounds
  }
}
