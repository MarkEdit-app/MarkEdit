//
//  NSSegmentedControl+Extension.swift
//
//  Created by cyan on 7/16/26.
//

import AppKit

public extension NSSegmentedControl {
  /// Assigns SF Symbol images to segments in order, with a shared image scaling.
  ///
  /// Names beyond `segmentCount` are ignored so an over-long list can't raise a range exception.
  func setSymbolImages(_ symbolNames: [String], scaling: NSImageScaling = .scaleProportionallyDown) {
    for (segment, symbolName) in symbolNames.enumerated() where segment < segmentCount {
      setImage(NSImage(systemSymbolName: symbolName), forSegment: segment)
      setImageScaling(scaling, forSegment: segment)
    }
  }
}
