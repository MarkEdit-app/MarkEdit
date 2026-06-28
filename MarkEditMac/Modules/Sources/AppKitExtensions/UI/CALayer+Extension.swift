//
//  CALayer+Extension.swift
//
//  Created by cyan on 6/27/26.
//

import QuartzCore

public extension CALayer {
  /// This layer and all descendants matching the predicate.
  func layers<T: CALayer>(where: (T) -> Bool) -> [T] {
    var results: [T] = []
    var stack = [self]

    while let node = stack.popLast() {
      if let layer = node as? T, `where`(layer) {
        results.append(layer)
      }

      stack.append(contentsOf: node.sublayers ?? [])
    }

    return results
  }

  /// Sets an input value on a named filter, skipping when that filter is absent.
  func setFilterValue(_ value: Double?, filterNamed name: String, key: String) {
    guard let value, hasFilter(named: name) else {
      return
    }

    setValue(value, forKeyPath: "filters.\(name).\(key)")
  }

  /// Returns true if the layer carries a filter with the given name.
  func hasFilter(named name: String) -> Bool {
    (filters ?? []).contains {
      ($0 as AnyObject).value(forKey: "name") as? String == name
    }
  }
}
