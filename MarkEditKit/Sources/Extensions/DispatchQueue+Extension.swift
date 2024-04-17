//
//  DispatchQueue+Extension.swift
//
//  Created by cyan on 12/13/22.
//

import Foundation

public extension DispatchQueue {
  @preconcurrency
  static func onMainThread(_ execute: @escaping @Sendable () -> Void) {
    if Thread.isMainThread {
      execute()
    } else {
      DispatchQueue.main.async(execute: execute)
    }
  }
}
