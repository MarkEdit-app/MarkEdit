//
//  WebPoint+Extension.swift
//
//  Created by cyan on 10/4/24.
//

import Foundation
import MarkEditCore

public extension WebPoint {
  var cgPoint: CGPoint {
    CGPoint(x: x, y: y)
  }
}
