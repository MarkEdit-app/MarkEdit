//
//  WebPoint+Extension.swift
//
//  Created by cyan on 2024/10/4.
//

import Foundation
import MarkEditCore

public extension WebPoint {
  var cgPoint: CGPoint {
    CGPoint(x: x, y: y)
  }
}
