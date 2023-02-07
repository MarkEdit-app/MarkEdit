//
//  DispatchQueue+Extension.swift
//
//  Created by cyan on 12/13/22.
//

import Foundation

public extension DispatchQueue {
  static func onMainThread(_ execute: @escaping () -> Void) {
    if Thread.isMainThread {
      execute()
    } else {
      DispatchQueue.main.async(execute: execute)
    }
  }

  static func afterDelay(seconds: TimeInterval, execute: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: execute)
  }
}
